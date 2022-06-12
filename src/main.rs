#![doc = include_str!("../README.md")]

use dotenv::dotenv;
use smallvec::SmallVec;
use teloxide::{
    dispatching::{Dispatcher, UpdateFilterExt as _},
    payloads::SendMessageSetters as _,
    requests::{Requester as _, RequesterExt as _, ResponseResult},
    types::{Message, Update, User},
};

#[tokio::main]
async fn main() {
    dotenv().ok();

    Dispatcher::builder(
        teloxide::Bot::from_env().auto_send(),
        Update::filter_message().branch(
            dptree::filter(is_new_group_member).endpoint(greet_new_member),
        ),
    )
    .build()
    .setup_ctrlc_handler()
    .dispatch()
    .await;
}

type Bot = teloxide::adaptors::AutoSend<teloxide::Bot>;

fn is_new_group_member(msg: Message) -> bool {
    msg.chat.is_group()
        && msg.new_chat_members().into_iter().flatten().any(is_regular_user)
}

fn is_regular_user(user: &User) -> bool {
    !user.is_bot
        && !user.is_anonymous()
        && !user.is_channel()
        && !user.is_telegram()
}

async fn greet_new_member(msg: Message, bot: Bot) -> ResponseResult<()> {
    let mentions = msg
        .new_chat_members()
        .into_iter()
        .flatten()
        .filter_map(|u| {
            is_regular_user(u)
                .then(|| u.mention().unwrap_or_else(|| u.full_name()))
        })
        .collect::<SmallVec<[_; 1]>>();

    bot.send_message(msg.chat.id, format!("Вітаємо, {}!", mentions.join(", ")))
        .reply_to_message_id(msg.id)
        .await?;

    Ok(())
}
