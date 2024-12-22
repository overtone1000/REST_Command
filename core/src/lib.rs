use std::{ops::Index, process::ExitStatus};

use hyper::{body::Incoming, Request, Response};
use hyper_services::{
    commons::{HandlerError, HandlerResult},
    response_building::full_to_boxed_body,
    service::{stateful_service::StatefulHandler, stateless_service::StatelessHandler},
};
use tokio::process::Command;

#[derive(Clone)]
pub struct Handler {
    command_directory: String,
}

impl Handler {
    pub fn new(command_directory: String) -> Handler {
        Handler {
            command_directory: command_directory,
        }
    }
}

impl StatefulHandler for Handler {
    async fn handle_request(self: Self, request: Request<Incoming>) -> HandlerResult {
        let method = request.method().clone();
        let path = request.uri().path().to_string();

        let command_string = match std::fs::read(self.command_directory + path.as_str()) {
            Ok(command) => match String::from_utf8(command) {
                Ok(command) => command,
                Err(e) => return Ok(Response::new(full_to_boxed_body(e.to_string()))),
            },
            Err(e) => return Ok(Response::new(full_to_boxed_body(e.to_string()))),
        };

        if command_string.len() == 0 {
            println!("Empty command.");
            return Ok(Response::new(full_to_boxed_body(
                "Empty command.".to_string(),
            )));
        }

        let (app, args) = match shell_words::split(command_string.as_str()) {
            Ok(split) => {
                let (app, args) = split.split_at(1);

                let app = app.first().expect("Should exist.");

                (app.to_owned(), args.to_owned())
            }
            Err(e) => {
                println!("Couldn't parse command {}", command_string);
                println!("{}", e.to_string());
                return Ok(Response::new(full_to_boxed_body(e.to_string())));
            }
        };

        let fut = Command::new(app).args(args).output();

        match fut.await {
            Ok(output) => {
                if output.status.success() {
                    println!("{:?}", output.stdout);
                    Ok(Response::new(full_to_boxed_body(output.stdout)))
                } else {
                    println!("Command executed but returned failure.");
                    println!("{:?}", output.stdout);
                    println!("{:?}", output.stderr);
                    Ok(Response::new(full_to_boxed_body(output.stderr)))
                }
            }
            Err(e) => {
                println!("Command failure.");
                Ok(Response::new(full_to_boxed_body(e.to_string())))
            }
        }
    }
}
