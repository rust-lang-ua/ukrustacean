use std::{borrow::Cow, env, hash::Hash, path::Path, sync::Arc};

use anyhow::anyhow;
use fluent_bundle::FluentValue;
use fluent_templates::{ArcLoader, Loader as _};
use unic_langid::LanguageIdentifier;

#[derive(Clone)]
pub struct L10n {
    loader: Arc<ArcLoader>,
    locale: LanguageIdentifier,
}

impl L10n {
    pub fn init() -> anyhow::Result<Self> {
        let locale = env::var("CONF_L10N_LOCALE")
            .map(|locale| Cow::Owned(locale))
            .unwrap_or_else(|_| Cow::Borrowed("en_US"))
            .as_ref()
            .parse::<LanguageIdentifier>()
            .map_err(|e| {
                anyhow!("Cannot parse `CONF_L10N_LOCALE` locale: {e}")
            })?;

        let dir_path = env::var_os("CONF_L10N_DIR")
            .map(|path| Cow::Owned(path.into()))
            .unwrap_or_else(|| Cow::Borrowed(Path::new("l10n/")));
        let loader = ArcLoader::builder(&dir_path, locale.clone())
            .build()
            .map_err(|e| anyhow!("Cannot initialize l10n: {e}"))?;

        Ok(Self { loader: Arc::new(loader), locale })
    }

    pub fn translate(&self, entry: impl AsRef<str>) -> String {
        self.loader.lookup(&self.locale, entry.as_ref())
    }

    pub fn translate_replace<ArgName, ArgValue, Args, Entry>(
        &self,
        entry: Entry,
        args: Args,
    ) -> String
    where
        Args: IntoIterator<Item = (ArgName, ArgValue)>,
        ArgName: AsRef<str> + Eq + Hash,
        ArgValue: Into<FluentValue<'static>>,
        Entry: AsRef<str>,
    {
        self.loader.lookup_with_args(
            &self.locale,
            entry.as_ref(),
            &args.into_iter().map(|(n, v)| (n, v.into())).collect(),
        )
    }
}
