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

        let root = std::env::current_dir().expect("Should have a current directory.");
        let absolute_path = self.command_directory.to_string() + path.as_str();
        let file = std::path::Path::new(absolute_path.as_str());

        if !file.is_file() {
            let mess = format!("{} is not a file", absolute_path);
            println!("{:?}", file);
            println!("{:?}", file.is_dir());
            println!("{:?}", file.exists());
            let e = std::io::Error::new(std::io::ErrorKind::NotFound, mess);
            return Err(Box::new(e));
        }

        //Set working directory to that of the file containing the command
        match file.parent() {
            Some(parent) => {
                match std::env::set_current_dir(parent) {
                    Ok(_) => (),
                    Err(_) => {
                        let mess = format!(
                            "Couldn't set working directory to parent of {}",
                            absolute_path
                        );
                        let e = std::io::Error::new(std::io::ErrorKind::NotFound, mess);
                        return Err(Box::new(e));
                    }
                };
            }
            None => {
                let mess = format!("{} has no parent directory", absolute_path);
                let e = std::io::Error::new(std::io::ErrorKind::NotFound, mess);
                return Err(Box::new(e));
            }
        };

        let command_string = match std::fs::read(file) {
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
        } else {
            println!("File contents: {}", command_string);
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

        println!("Command: {}", app);
        println!("Args: {:?}", args);

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
