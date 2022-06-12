#![doc = include_str!("../README.md")]

pub mod l10n;

use dotenv::dotenv;
use rand::Rng as _;
use smallvec::SmallVec;
use teloxide::{
    dispatching::{Dispatcher, UpdateFilterExt as _},
    payloads::SendMessageSetters as _,
    requests::{Requester as _, RequesterExt as _, ResponseResult},
    types::{Message, Update, User, ParseMode},
};

pub use self::l10n::L10n;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenv().ok();

    pretty_env_logger::init();
    log::info!("Starting Ukrustacean bot...");

    let l10n = L10n::init()?;

    Dispatcher::builder(
        teloxide::Bot::from_env().auto_send(),
        Update::filter_message().branch(
            dptree::filter(is_new_group_member).endpoint(greet_new_member),
        ),
    )
    .dependencies(dptree::deps![l10n])
    .build()
    .setup_ctrlc_handler()
    .dispatch()
    .await;

    Ok(())
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

async fn greet_new_member(
    msg: Message,
    bot: Bot,
    l10n: L10n,
) -> ResponseResult<()> {
    let mentions = msg
        .new_chat_members()
        .into_iter()
        .flatten()
        .filter_map(|u| {
            is_regular_user(u)
                .then(|| u.mention().unwrap_or_else(|| u.full_name()))
        })
        .collect::<SmallVec<[_; 1]>>();

    let num: u8 = rand::thread_rng().gen_range(1..=3);
    let answer = l10n.translate_replace(
        format!("greet-new-members-{num}"),
        [("users", mentions.join(", "))],
    );

    bot.send_message(msg.chat.id, answer)
        .reply_to_message_id(msg.id)
        .parse_mode(ParseMode::Html)
        .await
        .map(drop)
}
