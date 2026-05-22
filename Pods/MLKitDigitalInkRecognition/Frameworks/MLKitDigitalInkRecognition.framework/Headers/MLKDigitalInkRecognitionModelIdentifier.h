#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Represents a digital ink recognition model specific to a language, script, and optionally a
 * regional variant.
 */
NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier)
@interface MLKDigitalInkRecognitionModelIdentifier : NSObject

/** BCP 47 conformant language tag for this model. */
@property(nonatomic, readonly) NSString *languageTag;

/**
 * Language subtag, i.e. the 2 or 3-letter ISO 639 language code for this recognition model, e.g.
 * `"en"` for English.
 */
@property(nonatomic, readonly) NSString *languageSubtag;

/**
 * Script subtag, i.e. the four-letter ISO 15924 standard code of the script used in this
 * recognition model, e.g. `"Latn"` for Latin script or `"Arab"` for Arabic script.
 */
@property(nonatomic, readonly, nullable) NSString *scriptSubtag;

/**
 * Region subtag, i.e. the two-letter ISO 3166-1 Alpha 2 standard region codes or the set of
 * numeric codes defined by the UN M.49 standard, e.g. `"DE"` for Germany or `"002"` for Africa.
 */
@property(nonatomic, readonly, nullable) NSString *regionSubtag;

/** Use `from(languageTag:)` instead. */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Returns A model identifier that best matches the language, script (if
 * any), and region (if any) encoded in the BCP 47 formatted `languageTag`.
 *
 * <p>The matching is best-effort, i.e. it returns the model identifier that
 * best matches the provided `languageTag` using the following heuristics:
 *
 * <li>If no model identifier can be found for the requested language subtag, but the latter is
 * part of a supported macrolanguage, match against the macrolanguage, e.g. `"arb"` (Standard
 * Arabic) will match `"ar"` (Arabic).
 *
 * <li>If no script is provided, and no script is implicit for the requested language subtag, match
 * against any script.
 *
 * <li>If the provided or implicit script subtag is a subset of a supported script, match against
 * the latter as well, e.g. `"zh-Hant"` (Chinese, Traditional Han) will match against `"zh-Hani"`
 * (Chinese, Han).
 *
 * <li>If no region subtag is specified, match against any region, preferring model identifiers
 * that also do not specify a region, e.g. `"ro"` (Romanian) will match `"ro-RO"` (Romanian,
 * Romania).
 *
 * <li>If a region subtag is specified, but cannot be matched, match against regions containing the
 * specified region, e.g. `"fr-DZ"` (French, Algeria) will match against `"fr-002"` (French,
 * Africa).
 *
 * If no model identifier can be found, returns `nil`.
 *
 * @param languageTag An IETF BCP 47 language tag representing the requested language.
 * @param error Optional error message object, will be populated if the `languageTag` cannot be
 *     parsed.
 * @return a model identifier exactly matching the language tag provided, or the best approximate
 *     match, or `nil` if no appropriate model identifier can be found. Also set to `nil` if the
 *     language tag could not be parsed.
 */
+ (nullable MLKDigitalInkRecognitionModelIdentifier *)
    modelIdentifierFromLanguageTag:(NSString *)languageTag
                             error:(NSError **)error NS_SWIFT_NAME(from(languageTag:));

/**
 * Returns a model identifier that matches the given `languageTag` exactly.
 *
 * <p>Differs from `from(LanguageTag:)` in that it does not attempt to parse the `languageTag`
 * (and thus does not generate errors), and just returns the model identifier that matches
 * `languageTag` exactly, if it exists.
 *
 * @param languageTag The IETF BCP 47 language tag of the requested model identifier.
 * @return A `DigitalInkRecognitionModelIdentifier` matching the provided `languageTag` exactly, or
 *     `nil` if none was found.
 */
+ (nullable MLKDigitalInkRecognitionModelIdentifier *)modelIdentifierForLanguageTag:
    (NSString *)languageTag;

/** Returns the set of all available model identifiers. */
+ (NSSet<MLKDigitalInkRecognitionModelIdentifier *> *)allModelIdentifiers;

/**
 * Returns the set of model identifiers that support the given language subtag.
 *
 * E.g. for `"en"`, this would return a set of model identifiers containing `enUs`
 * (English, United States), `enUk` (English, United Kingdom), `enKe` (English, Kenya), etc.
 *
 * If no model identifiers supporting the language subtag can be found, returns an empty set.
 *
 * @param languageSubtag A 2 or 3-letter ISO 639 language code, e.g. `"en"` for English.
 * @return A set of model identifiers that support the provided `languageSubtag`, may be empty.
 */
+ (NSSet<MLKDigitalInkRecognitionModelIdentifier *> *)modelIdentifiersForLanguageSubtag:
    (NSString *)languageSubtag;

/**
 * Returns the set of model identifiers that support the given script subtag.
 *
 * E.g. for `"Latn"`, this would return a set of model identifiers containing
 * `enUs` (English, United States), `frFr` (French, France), `guLatn` (Gujarati, Latin script), etc.
 *
 * This function also returns model identifiers that support a superset of the given script
 * subtag, e.g. for `Hant` (Han, Traditional variant), this function will return the `zh-Hani`
 * recognition models since `Hant` is a subset of `Hani` (Han, both Traditional and
 * Simplified variants).
 *
 * If no model identifiers supporting the script subtag can be found, returns an empty set.
 *
 * @param scriptSubtag A four-letter ISO 15924 standard code, e.g. `"Latn"` for Latin script or
 *     `"Arab"` for Arabic script.
 * @return A set of model identifiers that support the provided `scriptSubtag`, may be empty.
 */
+ (NSSet<MLKDigitalInkRecognitionModelIdentifier *> *)modelIdentifiersForScriptSubtag:
    (NSString *)scriptSubtag;

/**
 * Returns the set of model identifiers that are specific to the given region subtag.
 *
 * E.g. for `"CH"`, this would return a set of model identifiers containing `deCh` (German,
 * Switzerland), `frCh` (French, Switzerland), `itCh` (Italian, Switzerland), and `rmCh` (Romansh,
 * Switzerland).
 *
 * This function also returns model identifiers specific to regions that contain the given
 * region subtag, or are contained by the given region subtag, e.g. searching for `DZ` (Algeria)
 * will produce results that include the `fr-002` (French, Africa) recognition model, and
 * vice-versa.
 *
 * If no model identifiers supporting the region subtag can be found, returns an empty set.
 *
 * @param regionSubtag A two-letter ISO 3166-1 Alpha 2 standard region code or one of the
 *     numeric codes defined by the UN M.49 standard, e.g. `"DE"` for Germany or `"002"` for Africa.
 * @return A set of model identifiers that are specific to the provided `regionSubtag`, may be
 * empty.
 */
+ (NSSet<MLKDigitalInkRecognitionModelIdentifier *> *)modelIdentifiersForRegionSubtag:
    (NSString *)regionSubtag;

@end

/*
 * Identifiers for models supported by the digital ink recognition API.
 *
 * Each recognition model is specific to a language and script, and optionally to a
 * regional variant.
 */
/**
 * Autodraw symbol recognition model.
 *
 * Model similar to that used by www.autodraw.com for sketch recognition. Given a collection of
 * strokes representing a drawing, returns a string identifying the object. Because of the inherent
 * ambiguity in recognizing some drawings, it is recommended to use multiple candidates, for example
 * by exposing them to the user and letting them decide.
 *
 * This recognition model provides scores via `DigitalInkRecognitionCandidate.score`.
 */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierAutodraw NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.autodraw);

/**
 * Emoji symbol recognition model.
 *
 * Recognizes single Emoji characters and returns them as Unicode code points. Because of the
 * inherent ambiguity in recognizing some drawings, it is recommended to use multiple candidates,
 * for example by exposing them to the user and letting them decide.
 *
 * This recognition model provides scores via `DigitalInkRecognitionCandidate.score`.
 */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEmoji NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.emoji);

/**
 * Shapes symbol recognition model.
 *
 * Given a collection of strokes representing a single shape, returns a string containing either
 * `RECTANGLE`, `TRIANGLE`, `ARROW`, or `ELLIPSE`.
 *
 * This recognition model provides scores via `DigitalInkRecognitionCandidate.score`.
 */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierShapes NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.shapes);

#pragma mark - Written language recognizers.

/** Afar, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierAaLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.aaLatn);

/** Ambonese Malay, Latin script, regional variant for Indonesia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierAbsLatnId NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.absLatnId);

/** Achinese, Latin script, regional variant for Indonesia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierAceLatnId NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.aceLatnId);

/** Achterhoeks, Latin script, regional variant for Netherlands. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierActLatnNl NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.actLatnNl);

/** Afrikaans, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierAf NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.af);

/** Amharic, Ethiopic script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierAm NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.am);

/** Aragonese, Latin script, regional variant for Spain. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierAnLatnEs NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.anLatnEs);

/** Anaang, Latin script, regional variant for Nigeria. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierAnwLatnNg NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.anwLatnNg);

/** Arabic, Arabic script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierAr NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ar);

/** Assamese, Bangla script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierAs NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.as);

/** Awadhi, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierAwaDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.awaDevaIn);

/** Azerbaijani, Latin script, regional variant for Azerbaijan. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierAzLatnAz NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.azLatnAz);

/** Bahamas Creole English, Latin script, regional variant for Bahamas. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBahLatnBs NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.bahLatnBs);

/** Bavarian, Latin script, regional variant for Austria. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBarLatnAt NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.barLatnAt);

/** Bench, Latin script, regional variant for Ethiopia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBcqLatnEt NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.bcqLatnEt);

/** Belarusian, Cyrillic script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.be);

/** Berber languages, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBerLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.berLatn);

/** Betawi, Latin script, regional variant for Indonesia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBewLatnId NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.bewLatnId);

/** Bagheli, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBfyDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.bfyDevaIn);

/** Mahasu Pahari, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBfzDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.bfzDevaIn);

/** Bulgarian, Cyrillic script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBg NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.bg);

/** Haryanvi, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBgcDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.bgcDevaIn);

/** Bagri, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBgqDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.bgqDevaIn);

/** Bagri, Devanagari script, regional variant for Pakistan. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBgqDevaPk NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.bgqDevaPk);

/** Balkan Gagauz Turkish, Latin script, regional variant for Turkey. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBgxLatnTr NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.bgxLatnTr);

/** Banggai, Latin script, regional variant for Indonesia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBgzLatnId NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.bgzLatnId);

/** Bhili, Devanagari script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBhbDeva NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.bhbDeva);

/** Bhojpuri, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBhoDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.bhoDevaIn);

/** Bislama, Latin script, regional variant for Vanuatu. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBiLatnVu NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.biLatnVu);

/** Bikol, Latin script, regional variant for Philippines. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBikLatnPh NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.bikLatnPh);

/** Kanauji, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBjjDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.bjjDevaIn);

/** Banjar, Latin script, regional variant for Indonesia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBjnLatnId NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.bjnLatnId);

/** Bangla, Bangla script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.bn);

/** Bangla, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBnLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.bnLatn);

/** Tibetan, Tibetan script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBoTibt NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.boTibt);

/** Berom, Latin script, regional variant for Nigeria. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBomLatnNg NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.bomLatnNg);

/** Bodo, Devanagari script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBrxDeva NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.brxDeva);

/** Bodo, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBrxLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.brxLatn);

/** Bosnian, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBs NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.bs);

/** Rinconada Bikol, Latin script, regional variant for Philippines. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBtoLatnPh NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.btoLatnPh);

/** Batak Alas-Kluet, Latin script, regional variant for Indonesia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBtzLatnId NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.btzLatnId);

/** Southern Betsimisaraka Malagasy, Latin script, regional variant for Madagascar. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierBzcLatnMg NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.bzcLatnMg);

/** Catalan, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierCa NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ca);

/** Cebuano, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierCebLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.cebLatn);

/** Chiga, Latin script, regional variant for Uganda. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierCggLatnUg NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.cggLatnUg);

/** Chamorro, Latin script, regional variant for Guam. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierChGu NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.chGu);

/** Chokwe, Latin script, regional variant for Congo - Kinshasa. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierCjkLatnCd NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.cjkLatnCd);

/** Corsican, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierCoLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.coLatn);

/** Capiznon, Latin script, regional variant for Philippines. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierCpsLatnPh NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.cpsLatnPh);

/** Seselwa Creole French, Latin script, regional variant for Seychelles. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierCrsLatnSc NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.crsLatnSc);

/** Czech, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierCs NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.cs);

/** Welsh, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierCy NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.cy);

/** Cuyonon, Latin script, regional variant for Philippines. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierCyoLatnPh NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.cyoLatnPh);

/** Danish, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierDa NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.da);

/** German, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierDe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.de);

/** German, Latin script, regional variant for Austria. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierDeAt NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.deAt);

/** German, Latin script, regional variant for Belgium. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierDeBe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.deBe);

/** German, Latin script, regional variant for Switzerland. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierDeCh NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.deCh);

/** German, Latin script, regional variant for Germany. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierDeDe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.deDe);

/** German, Latin script, regional variant for Luxembourg. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierDeLu NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.deLu);

/** Dan, Latin script, regional variant for Côte d’Ivoire. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierDnjLatnCi NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.dnjLatnCi);

/** Dogri, Devanagari script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierDoiDeva NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.doiDeva);

/** Dogri, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierDoiLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.doiLatn);

/** Gedeo, Latin script, regional variant for Ethiopia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierDrsLatnEt NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.drsLatnEt);

/** Drents, Latin script, regional variant for Netherlands. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierDrtLatnNl NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.drtLatnNl);

/** Lower Sorbian, Latin script, regional variant for Germany. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierDsbDe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.dsbDe);

/** Greek, Greek script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEl NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.el);

/** English, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.en);

/** English, Latin script, regional variant for Australia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEnAu NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.enAu);

/** English, Latin script, regional variant for Canada. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEnCa NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.enCa);

/** English, Latin script, regional variant for UK. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEnGb NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.enGb);

/** English, Latin script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEnIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.enIn);

/** English, Latin script, regional variant for Kenya. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEnKe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.enKe);

/** English, Latin script, regional variant for Nigeria. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEnNg NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.enNg);

/** English, Latin script, regional variant for Philippines. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEnPh NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.enPh);

/** English, Latin script, regional variant for US. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEnUs NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.enUs);

/** English, Latin script, regional variant for South Africa. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEnZa NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.enZa);

/** Esperanto, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEo NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.eo);

/** Spanish, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEs NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.es);

/** Spanish, Latin script, regional variant for Argentina. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEsAr NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.esAr);

/** Spanish, Latin script, regional variant for Spain. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEsEs NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.esEs);

/** Spanish, Latin script, regional variant for Mexico. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEsMx NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.esMx);

/** Spanish, Latin script, regional variant for US. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEsUs NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.esUs);

/** Estonian, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEt NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.et);

/** Estonian, Latin script, regional variant for Estonia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEtEe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.etEe);

/** Basque, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEu NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.eu);

/** Basque, Latin script, regional variant for Spain. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierEuEs NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.euEs);

/** Extremaduran, Latin script, regional variant for Spain. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierExtLatnEs NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.extLatnEs);

/** Persian, Arabic script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierFa NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.fa);

/** Fang, Latin script, regional variant for Equatorial Guinea. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierFanLatnGq NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.fanLatnGq);

/** Finnish, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierFi NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.fi);

/** Filipino, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierFilLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.filLatn);

/** Fijian, Latin script, regional variant for Fiji. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierFjFj NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.fjFj);

/** Faroese, Latin script, regional variant for Faroe Islands. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierFoFo NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.foFo);

/** French, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierFr NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.fr);

/** French, Latin script, regional variant for Africa. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierFr002 NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.fr002);

/** French, Latin script, regional variant for Belgium. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierFrBe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.frBe);

/** French, Latin script, regional variant for Canada. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierFrCa NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.frCa);

/** French, Latin script, regional variant for Switzerland. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierFrCh NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.frCh);

/** French, Latin script, regional variant for France. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierFrFr NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.frFr);

/** Western Frisian, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierFy NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.fy);

/** Irish, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierGa NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ga);

/** Borana-Arsi-Guji Oromo, Latin script, regional variant for Ethiopia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierGaxLatnEt NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.gaxLatnEt);

/** Gayo, Latin script, regional variant for Indonesia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierGayLatnId NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.gayLatnId);

/** Garhwali, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierGbmDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.gbmDevaIn);

/** Guianese Creole French, Latin script, regional variant for French Guiana. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierGcrLatnGf NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.gcrLatnGf);

/** Scottish Gaelic, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierGdLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.gdLatn);

/** Scottish Gaelic, Latin script, regional variant for UK. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierGdLatnGb NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.gdLatnGb);

/** Godwari, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierGdxDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.gdxDevaIn);

/** Gujari, Devanagari script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierGjuDeva NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.gjuDeva);

/** Galician, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierGl NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.gl);

/** Galician, Latin script, regional variant for Spain. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierGlEs NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.glEs);

/** Gronings, Latin script, regional variant for Netherlands. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierGosLatnNl NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.gosLatnNl);

/** Ghanaian Pidgin English, Latin script, regional variant for Ghana. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierGpeLatnGh NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.gpeLatnGh);

/** Swiss German, Latin script, regional variant for Switzerland. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierGswCh NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.gswCh);

/** Gujarati, Gujarati script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierGu NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.gu);

/** Gujarati, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierGuLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.guLatn);

/** Manx, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierGv NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.gv);

/** Guyanese Creole English, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierGynLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.gynLatn);

/** Ha, Latin script, regional variant for Tanzania. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierHaqLatnTz NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.haqLatnTz);

/** Hawaiian, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierHawLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.hawLatn);

/** Hadiyya, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierHdyLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.hdyLatn);

/** Hebrew, Hebrew script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierHe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.he);

/** Hindi, Devanagari script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierHi NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.hi);

/** Hindi, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierHiLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.hiLatn);

/** Fiji Hindi, Devanagari script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierHifDeva NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.hifDeva);

/** Hiligaynon, Latin script, regional variant for Philippines. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierHilLatnPh NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.hilLatnPh);

/** Hmong, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierHmnLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.hmnLatn);

/** Chhattisgarhi, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierHneDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.hneDevaIn);

/** Hani, Latin script, regional variant for China. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierHniLatnCn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.hniLatnCn);

/** Hiri Motu, Latin script, regional variant for Papua New Guinea. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierHoLatnPg NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.hoLatnPg);

/** Hadothi, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierHojDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.hojDevaIn);

/** Croatian, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierHr NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.hr);

/** Hunsrik, Latin script, regional variant for Brazil. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierHrxLatnBr NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.hrxLatnBr);

/** Haitian Creole, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierHt NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ht);

/** Hungarian, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierHu NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.hu);

/** Armenian, Armenian script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierHy NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.hy);

/** Indonesian, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierId NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.id);

/** Ebira, Latin script, regional variant for Nigeria. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierIgbLatnNg NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.igbLatnNg);

/** Sichuan Yi, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierIiLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.iiLatn);

/** Iloko, Latin script, regional variant for Philippines. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierIloLatnPh NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.iloLatnPh);

/** Icelandic, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierIs NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.is);

/** Italian, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierIt NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.it);

/** Italian, Latin script, regional variant for Switzerland. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierItCh NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.itCh);

/** Italian, Latin script, regional variant for Italy. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierItIt NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.itIt);

/** Iu Mien, Latin script, regional variant for China. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierIumLatnCn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.iumLatnCn);

/** Japanese, Japanese script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierJa NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ja);

/** Jamaican Creole English, Latin script, regional variant for Jamaica. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierJamLatnJm NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.jamLatnJm);

/** Jambi Malay, Latin script, regional variant for Indonesia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierJaxLatnId NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.jaxLatnId);

/** Lojban, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierJboLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.jboLatn);

/** Javanese, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierJvLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.jvLatn);

/** Georgian, Georgian script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKa NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ka);

/** Makonde, Latin script, regional variant for Tanzania. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKdeLatnTz NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.kdeLatnTz);

/** Kachhi, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKfrDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.kfrDevaIn);

/** Kumaoni, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKfyDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.kfyDevaIn);

/** Komering, Latin script, regional variant for Indonesia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKgeLatnId NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.kgeLatnId);

/** Khasi, Latin script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKhaLatnIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.khaLatnIn);

/** Kuanyama, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKjLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.kjLatn);

/** Kazakh, Cyrillic script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKk NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.kk);

/** Kalaallisut, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKl NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.kl);

/** Khmer, Khmer script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKm NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.km);

/** Kimbundu, Latin script, regional variant for Angola. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKmbLatnAo NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.kmbLatnAo);

/** Khorasani Turkish, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKmzLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.kmzLatn);

/** Kannada, Kannada script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.kn);

/** Kannada, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKnLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.knLatn);

/** Korean, Korean script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKo NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ko);

/** Konkani, Devanagari script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKok NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.kok);

/** Konkani, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKokIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.kokIn);

/** Konkani, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKokLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.kokLatn);

/** Kurukh, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKruDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.kruDevaIn);

/** Kashmiri, Devanagari script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKsDeva NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ksDeva);

/** Kashmiri, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKsLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ksLatn);

/** Colognian, Latin script, regional variant for Germany. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKshLatnDe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.kshLatnDe);

/** Kambaata, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKtbLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ktbLatn);

/** Kituba, Latin script, regional variant for Congo - Kinshasa. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKtuLatnCd NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ktuLatnCd);

/** Kurdish, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKuLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.kuLatn);

/** Cornish, Latin script, regional variant for UK. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKwLatnGb NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.kwLatnGb);

/** Kyrgyz, Cyrillic script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierKyCyrl NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.kyCyrl);

/** Latin, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierLa NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.la);

/** Ladino, Latin script, regional variant for Bosnia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierLadLatnBa NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ladLatnBa);

/** Lango (Uganda), Latin script, regional variant for Uganda. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierLajLatnUg NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.lajLatnUg);

/** Luxembourgish, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierLb NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.lb);

/** Lendu, Latin script, regional variant for Congo - Kinshasa. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierLedLatnCd NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ledLatnCd);

/** Ladin, Latin script, regional variant for Italy. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierLldLatnIt NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.lldLatnIt);

/** Lambadi, Devanagari script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierLmnDeva NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.lmnDeva);

/** Lao, Lao script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierLo NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.lo);

/** Malawi Lomwe, Latin script, regional variant for Malawi. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierLonLatnMw NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.lonLatnMw);

/** Lithuanian, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierLt NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.lt);

/** Luyia, Latin script, regional variant for Kenya. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierLuyLatnKe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.luyLatnKe);

/** Latvian, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierLv NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.lv);

/** Madurese, Latin script, regional variant for Indonesia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMadLatnId NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.madLatnId);

/** Magahi, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMagDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.magDevaIn);

/** Maithili, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMaiIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.maiIn);

/** Maithili, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMaiLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.maiLatn);

/** Masai, Latin script, regional variant for Kenya. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMasLatnKe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.masLatnKe);

/** North Moluccan Malay, Latin script, regional variant for Indonesia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMaxLatnId NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.maxLatnId);

/** Maguindanaon, Latin script, regional variant for Philippines. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMdhLatnPh NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.mdhLatnPh);

/** Central Melanau, Latin script, regional variant for Malaysia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMelLatnMy NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.melLatnMy);

/** Kedah Malay, Latin script, regional variant for Malaysia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMeoLatnMy NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.meoLatnMy);

/** Bangka, Latin script, regional variant for Indonesia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMfbLatnId NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.mfbLatnId);

/** Makassar Malay, Latin script, regional variant for Indonesia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMfpLatnId NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.mfpLatnId);

/** Malagasy, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMg NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.mg);

/** Maori, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMiLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.miLatn);

/** Minangkabau, Latin script, regional variant for Indonesia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMinLatnId NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.minLatnId);

/** Macedonian, Cyrillic script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMk NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.mk);

/** Malayalam, Malayalam script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMl NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ml);

/** Malayalam, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMlLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.mlLatn);

/** Mongolian, Cyrillic script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMnCyrl NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.mnCyrl);

/** Manipuri, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMniLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.mniLatn);

/** Manggarai, Latin script, regional variant for Indonesia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMqyLatnId NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.mqyLatnId);

/** Marathi, Devanagari script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMr NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.mr);

/** Marathi, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMrIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.mrIn);

/** Marathi, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMrLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.mrLatn);

/** Maranao, Latin script, regional variant for Philippines. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMrwLatnPh NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.mrwLatnPh);

/** Malay, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMs NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ms);

/** Malay, Latin script, regional variant for Brunei. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMsBn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.msBn);

/** Malay, Latin script, regional variant for Malaysia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMsMy NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.msMy);

/** Sabah Malay, Latin script, regional variant for Malaysia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMsiLatnMy NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.msiLatnMy);

/** Maltese, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMt NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.mt);

/** Mewari, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMtrDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.mtrDevaIn);

/** Musi, Latin script, regional variant for Indonesia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMuiLatnId NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.muiLatnId);

/** Malvi, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMupDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.mupDevaIn);

/** Marwari (Pakistan), Devanagari script, regional variant for Pakistan. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMveDevaPk NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.mveDevaPk);

/** Marwari, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMwrDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.mwrDevaIn);

/** Hmong Daw, Latin script, regional variant for China. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMwwLatnCn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.mwwLatnCn);

/** Burmese, Myanmar script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMy NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.my);

/** Masaaba, Latin script, regional variant for Uganda. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierMyxLatnUg NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.myxLatnUg);

/** Nahuatl languages, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierNahLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.nahLatn);

/** Neapolitan, Latin script, regional variant for Italy. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierNapLatnIt NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.napLatnIt);

/** Ndau, Latin script, regional variant for Zimbabwe. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierNdcLatnZw NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ndcLatnZw);

/** Nepali, Devanagari script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierNe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ne);

/** Nepali, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierNeIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.neIn);

/** Nepali, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierNeLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.neLatn);

/** Nepali, Devanagari script, regional variant for Nepal. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierNeNp NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.neNp);

/** Newari, Devanagari script, regional variant for Nepal. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierNewDevaNp NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.newDevaNp);

/** Ndonga, Latin script, regional variant for Namibia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierNgLatnNa NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ngLatnNa);

/** Ngbaka, Latin script, regional variant for Congo - Kinshasa. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierNgaLatnCd NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ngaLatnCd);

/** Nandi, Latin script, regional variant for Kenya. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierNiqLatnKe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.niqLatnKe);

/** Dutch, Latin script, regional variant for Belgium. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierNlBe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.nlBe);

/** Dutch, Latin script, regional variant for Netherlands. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierNlNl NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.nlNl);

/** Norwegian Nynorsk, Latin script, regional variant for Norway. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierNnNo NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.nnNo);

/** Norwegian, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierNo NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.no);

/** Nimadi, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierNoeDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.noeDevaIn);

/** South Ndebele, Latin script, regional variant for South Africa. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierNrZa NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.nrZa);

/** Northern Sotho, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierNso NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.nso);

/** Nyanja, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierNy NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ny);

/** Nyamwezi, Latin script, regional variant for Tanzania. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierNymLatnTz NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.nymLatnTz);

/** Nyoro, Latin script, regional variant for Uganda. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierNyoLatnUg NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.nyoLatnUg);

/** Occitan, Latin script, regional variant for France. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierOcLatnFr NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ocLatnFr);

/** Ojibwa, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierOjLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ojLatn);

/** Livvi, Latin script, regional variant for Russia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierOloLatnRu NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.oloLatnRu);

/** Oromo, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierOm NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.om);

/** Odia, Odia script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierOr NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.or);

/** Odia, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierOrLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.orLatn);

/** Punjabi, Gurmukhi script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierPa NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.pa);

/** Punjabi, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierPaLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.paLatn);

/** Pangasinan, Latin script, regional variant for Philippines. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierPagLatnPh NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.pagLatnPh);

/** Pampanga, Latin script, regional variant for Philippines. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierPamLatnPh NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.pamLatnPh);

/** Papiamento, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierPapLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.papLatn);

/** Bouyei, Latin script, regional variant for China. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierPccLatnCn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.pccLatnCn);

/** Picard, Latin script, regional variant for Belgium. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierPcdLatnBe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.pcdLatnBe);

/** Nigerian Pidgin, Latin script, regional variant for Nigeria. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierPcmLatnNg NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.pcmLatnNg);

/** Pökoot, Latin script, regional variant for Kenya. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierPkoLatnKe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.pkoLatnKe);

/** Polish, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierPl NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.pl);

/** Piedmontese, Latin script, regional variant for Italy. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierPmsLatnIt NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.pmsLatnIt);

/** Papuan Malay, Latin script, regional variant for Indonesia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierPmyLatnId NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.pmyLatnId);

/** Upper Guinea Crioulo, Latin script, regional variant for Guinea-Bissau. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierPovLatnGw NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.povLatnGw);

/** Parauk, Latin script, regional variant for Myanmar. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierPrkLatnMm NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.prkLatnMm);

/** Central Malay, Latin script, regional variant for Indonesia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierPseLatnId NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.pseLatnId);

/** Portuguese, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierPt NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.pt);

/** Portuguese, Latin script, regional variant for Africa. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierPt002 NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.pt002);

/** Portuguese, Latin script, regional variant for Brazil. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierPtBr NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ptBr);

/** Portuguese, Latin script, regional variant for Portugal. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierPtPt NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ptPt);

/** Quechua, Latin script, regional variant for Peru. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierQuPe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.quPe);

/** Kʼicheʼ, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierQucLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.qucLatn);

/** Réunion Creole French, Latin script, regional variant for Réunion. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierRcfLatnRe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.rcfLatnRe);

/** Rangpuri, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierRktDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.rktDevaIn);

/** Romansh, Latin script, regional variant for Switzerland. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierRmCh NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.rmCh);

/** Rundi, Latin script, regional variant for Burundi. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierRnBi NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.rnBi);

/** Romanian, Latin script, regional variant for Romania. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierRoRo NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.roRo);

/** Russian, Cyrillic script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierRu NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ru);

/** Marwari (India), Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierRwrDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.rwrDevaIn);

/** Sanskrit, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSaDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.saDevaIn);

/** Sanskrit, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSaLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.saLatn);

/** Santali, Devanagari script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSatDeva NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.satDeva);

/** Santali, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSatLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.satLatn);

/** Sardinian, Latin script, regional variant for Italy. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierScLatnIt NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.scLatnIt);

/** Sadri, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSckDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.sckDevaIn);

/** Scots, Latin script, regional variant for UK. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierScoLatnGb NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.scoLatnGb);

/** Sindhi, Devanagari script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSdDeva NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.sdDeva);

/** Sindhi, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSdLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.sdLatn);

/** Sassarese Sardinian, Latin script, regional variant for Italy. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSdcLatnIt NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.sdcLatnIt);

/** Sango, Latin script, regional variant for Central African Republic. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSgCf NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.sgCf);

/** Kipsigis, Latin script, regional variant for Kenya. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSgcLatnKe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.sgcLatnKe);

/** Surgujia, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSgjDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.sgjDevaIn);

/** Samogitian, Latin script, regional variant for Lithuania. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSgsLatnLt NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.sgsLatnLt);

/** Sinhala, Sinhala script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSi NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.si);

/** Slovak, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSk NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.sk);

/** Sakalava Malagasy, Latin script, regional variant for Madagascar. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSkgLatnMg NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.skgLatnMg);

/** Slovenian, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSl NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.sl);

/** Samoan, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSm NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.sm);

/** Shona, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSnLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.snLatn);

/** Somali, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSo NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.so);

/** Albanian, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSq NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.sq);

/** Serbian, Cyrillic script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSrCyrl NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.srCyrl);

/** Serbian, Latin script, regional variant for Serbia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSrLatnRs NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.srLatnRs);

/** Swati, Latin script, regional variant for Eswatini. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSsSz NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ssSz);

/** Silt'e, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierStvLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.stvLatn);

/** Sundanese, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSuLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.suLatn);

/** Sukuma, Latin script, regional variant for Tanzania. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSukLatnTz NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.sukLatnTz);

/** Swedish, Latin script, regional variant for Finland. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSvFi NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.svFi);

/** Swedish, Latin script, regional variant for Sweden. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSvSe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.svSe);

/** Swahili, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSw NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.sw);

/** Shekhawati, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSwvDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.swvDevaIn);

/** Upper Saxon, Latin script, regional variant for Germany. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSxuLatnDe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.sxuLatnDe);

/** Sylheti, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierSylLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.sylLatn);

/** Tamil, Tamil script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierTa NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ta);

/** Tamil, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierTaLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.taLatn);

/** Tandroy-Mahafaly Malagasy, Latin script, regional variant for Madagascar. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierTdxLatnMg NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.tdxLatnMg);

/** Telugu, Telugu script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierTe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.te);

/** Telugu, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierTeLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.teLatn);

/** Tetum, Latin script, regional variant for Timor-Leste. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierTetLatnTl NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.tetLatnTl);

/** Tajik, Cyrillic script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierTgCyrl NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.tgCyrl);

/** Thai, Thai script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierTh NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.th);

/** Tigrinya, Ethiopic script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierTi NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ti);

/** Turkmen, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierTkLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.tkLatn);

/** Tswana, Latin script, regional variant for Botswana. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierTnBw NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.tnBw);

/** Tok Pisin, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierTpi NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.tpi);

/** Turkish, Latin script, regional variant for Turkey. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierTrTr NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.trTr);

/** Trinidadian Creole English, Latin script, regional variant for Trinidad & Tobago. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierTrfLatnTt NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.trfLatnTt);

/** Kok Borok, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierTrpLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.trpLatn);

/** Tsonga, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierTs NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ts);

/** Tausug, Latin script, regional variant for Philippines. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierTsgLatnPh NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.tsgLatnPh);

/** Tumbuka, Latin script, regional variant for Malawi. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierTumLatnMw NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.tumLatnMw);

/** Turkana, Latin script, regional variant for Kenya. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierTuvLatnKe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.tuvLatnKe);

/** Twents, Latin script, regional variant for Netherlands. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierTwdLatnNl NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.twdLatnNl);

/** Ukrainian, Cyrillic script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierUk NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.uk);

/** Mundari, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierUnrDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.unrDevaIn);

/** Mundari, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierUnrLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.unrLatn);

/** Urdu, Arabic script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierUr NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ur);

/** Urdu, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierUrLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.urLatn);

/** Urdu, Arabic script, regional variant for Pakistan. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierUrPk NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.urPk);

/** Uzbek, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierUzLatn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.uzLatn);

/** Veluws, Latin script, regional variant for Netherlands. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierVelLatnNl NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.velLatnNl);

/** Veps, Latin script, regional variant for Russia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierVepLatnRu NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.vepLatnRu);

/** Vietnamese, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierVi NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.vi);

/** Tenggarong Kutai Malay, Latin script, regional variant for Indonesia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierVktLatnId NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.vktLatnId);

/** Walloon, Latin script, regional variant for Belgium. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierWaLatnBe NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.waLatnBe);

/** Wagdi, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierWbrDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.wbrDevaIn);

/** Merwari, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierWryDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.wryDevaIn);

/** Xhosa, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierXh NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.xh);

/** Manado Malay, Latin script, regional variant for Indonesia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierXmmLatnId NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.xmmLatnId);

/** Kangri, Devanagari script, regional variant for India. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierXnrDevaIn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.xnrDevaIn);

/** Maay, Latin script, regional variant for Somalia. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierYmmLatnSo NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.ymmLatnSo);

/** Zhuang, Latin script, regional variant for China. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierZaLatnCn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.zaLatnCn);

/** Chinese, Han script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierZhHani NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.zhHani);

/** Chinese, Han script, regional variant for China. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierZhHaniCn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.zhHaniCn);

/** Chinese, Han script, regional variant for Hong Kong. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierZhHaniHk NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.zhHaniHk);

/** Chinese, Han script, regional variant for Taiwan. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierZhHaniTw NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.zhHaniTw);

/** Zulu, Latin script. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierZu NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.zu);

/** Youjiang Zhuang, Latin script, regional variant for China. */
extern MLKDigitalInkRecognitionModelIdentifier
    *const MLKDigitalInkRecognitionModelIdentifierZyjLatnCn NS_SWIFT_NAME(DigitalInkRecognitionModelIdentifier.zyjLatnCn);
// NOLINTNEXTLINE
// LINT.ThenChange(//depot/google3/java/com/google/android/libraries/mlkit/granules/vision/digital_ink/scripts/prepare_manifest_for_mlkit.py)

NS_ASSUME_NONNULL_END
