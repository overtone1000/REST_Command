use std::{
    env,
    net::{IpAddr, Ipv4Addr},
};

use hyper_services::{
    service::{stateful_service::StatefulService, stateless_service::StatelessService},
    spawn_server,
};
use rest_commands::Handler;

#[tokio::main]
async fn main() {
    let args: Vec<String> = env::args().collect();

    let port = match args.get(1) {
        Some(port) => match port.parse::<u16>() {
            Ok(port) => port,
            Err(e) => {
                println!("Invalid port {}", port);
                println!("{}", e.to_string());
                return;
            }
        },
        None => {
            println!("Provide the desired port as the first argument.");
            return;
        }
    };

    let command_directory = match args.get(2) {
        Some(command_directory) => match std::fs::metadata(command_directory) {
            Ok(meta) => {
                if !meta.is_dir() {
                    println!(
                        "Provided argument {} is not a directory.",
                        command_directory
                    );
                    return;
                } else {
                    command_directory
                }
            }
            Err(e) => {
                println!(
                    "Error attempting to get directory metadata for {}.",
                    command_directory
                );
                println!("{}", e.to_string());
                return;
            }
        },
        None => {
            println!("Provide the directory containing commands as the second argument.");
            return;
        }
    };

    println!("Starting REST Service");

    let handler = Handler::new(command_directory.clone());

    let event_server = spawn_server(
        IpAddr::V4(Ipv4Addr::LOCALHOST),
        port,
        StatefulService::create(handler.clone()),
    );

    match event_server.await {
        Ok(_) => println!("Closed REST Service Gracefully"),
        Err(e) => {
            println!("REST Service Failure");
            println!("{}", e.to_string());
        }
    };
}
