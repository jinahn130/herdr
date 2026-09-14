use std::fs::OpenOptions;
use std::io::{self, Write};
use std::path::Path;
use std::time::{SystemTime, UNIX_EPOCH};

use serde::Serialize;
use sha2::{Digest, Sha256};

const JOURNAL_FILE: &str = "programmatic-prompts.jsonl";

#[derive(Serialize)]
struct ProgrammaticPromptRecord<'a> {
    source: &'static str,
    session_id: &'a str,
    provider: &'a str,
    sha256: String,
    unix_ms: u128,
}

pub(super) fn record_agent_prompt(response: &serde_json::Value, text: &str) {
    let path = crate::config::state_dir().join(JOURNAL_FILE);
    if let Err(err) = record_agent_prompt_at(&path, response, text, SystemTime::now()) {
        eprintln!(
            "warning: Herdr could not record programmatic prompt provenance at {}: {err}",
            path.display()
        );
    }
}

fn record_agent_prompt_at(
    path: &Path,
    response: &serde_json::Value,
    text: &str,
    now: SystemTime,
) -> io::Result<bool> {
    let Some(result) = response.get("result") else {
        return Ok(false);
    };
    if result.get("type").and_then(serde_json::Value::as_str) != Some("agent_prompted") {
        return Ok(false);
    }
    let Some(agent) = result.get("agent") else {
        return Ok(false);
    };
    let Some(session) = agent.get("agent_session") else {
        return Ok(false);
    };
    let Some(session_id) = session.get("value").and_then(serde_json::Value::as_str) else {
        return Ok(false);
    };
    if session_id.is_empty() {
        return Ok(false);
    }

    let provider = session
        .get("agent")
        .and_then(serde_json::Value::as_str)
        .unwrap_or_default();
    let unix_ms = now
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis();
    let record = ProgrammaticPromptRecord {
        source: "herdr_agent_prompt",
        session_id,
        provider,
        sha256: format!("{:x}", Sha256::digest(text.as_bytes())),
        unix_ms,
    };
    let mut encoded = serde_json::to_vec(&record).map_err(io::Error::other)?;
    encoded.push(b'\n');

    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent)?;
    }
    let mut options = OpenOptions::new();
    options.create(true).append(true);
    #[cfg(unix)]
    {
        use std::os::unix::fs::OpenOptionsExt;
        options.mode(0o600);
    }
    options.open(path)?.write_all(&encoded)?;
    Ok(true)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn prompted_response() -> serde_json::Value {
        serde_json::json!({
            "id": "cli:agent:prompt",
            "result": {
                "type": "agent_prompted",
                "agent": {
                    "pane_id": "w1:p2",
                    "agent_session": {
                        "source": "detected",
                        "agent": "codex",
                        "kind": "uuid",
                        "value": "session-123"
                    }
                }
            }
        })
    }

    #[test]
    fn records_hash_and_identity_without_plaintext() {
        let path = std::env::temp_dir().join(format!(
            "herdr-programmatic-prompt-{}-{}.jsonl",
            std::process::id(),
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_nanos()
        ));
        let text = "private coordination payload";
        let wrote = record_agent_prompt_at(
            &path,
            &prompted_response(),
            text,
            UNIX_EPOCH + std::time::Duration::from_millis(42),
        )
        .unwrap();
        assert!(wrote);

        let contents = std::fs::read_to_string(&path).unwrap();
        let record: serde_json::Value = serde_json::from_str(contents.trim()).unwrap();
        assert_eq!(record["source"], "herdr_agent_prompt");
        assert_eq!(record["session_id"], "session-123");
        assert_eq!(record["provider"], "codex");
        assert_eq!(record["unix_ms"], 42);
        assert_eq!(
            record["sha256"],
            format!("{:x}", Sha256::digest(text.as_bytes()))
        );
        assert!(!contents.contains(text));
        std::fs::remove_file(path).unwrap();
    }

    #[test]
    fn ignores_failed_or_sessionless_responses() {
        let path = std::env::temp_dir().join(format!(
            "herdr-programmatic-prompt-{}-missing.jsonl",
            std::process::id()
        ));
        let _ = std::fs::remove_file(&path);
        let failed = serde_json::json!({"error": {"code": "nope"}});
        assert!(!record_agent_prompt_at(&path, &failed, "text", UNIX_EPOCH).unwrap());

        let mut sessionless = prompted_response();
        sessionless["result"]["agent"]
            .as_object_mut()
            .unwrap()
            .remove("agent_session");
        assert!(!record_agent_prompt_at(&path, &sessionless, "text", UNIX_EPOCH).unwrap());
        assert!(!path.exists());
    }
}
