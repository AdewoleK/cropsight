import 'knowledge_card.dart';

/// The on-device knowledge base.
///
/// Kept as Dart data (rather than loose asset files) so it is guaranteed to be
/// available offline and needs no asset-manifest parsing. Content is concise,
/// field-oriented, and covers the most economically important crop problems
/// for smallholder farmers across Sub-Saharan Africa (West, East, Central and
/// Southern). Chemical options are named only by active-ingredient class and
/// always defer to the product label. Bump [version] when you edit cards so
/// cached embeddings are rebuilt.
class KnowledgeBase {
  const KnowledgeBase._();

  /// Increment whenever [cards] changes, so the vector index re-embeds.
  static const int version = 2;

  // Shared safety notes, reused by cards whose management mentions a
  // chemical. Never put rates or day counts here: always defer to the label.
  static const String _spraySafety =
      'Wear gloves, a face mask, long sleeves and boots when mixing and '
      'spraying. Use only the rate on the product label. Wait the full '
      'pre-harvest interval on the label before harvesting. Keep children and '
      'animals away. Do not spray in wind or near water. Wash after spraying.';

  static const String _seedTreatmentSafety =
      'Wear gloves when treating or handling treated seed. Use only the rate '
      'on the product label. Never eat treated seed or feed it to animals. Keep '
      'it away from children. Wash hands and equipment away from streams and '
      'wells.';

  static const String _storageSafety =
      'Use only products labelled for stored grain or seed, at the label rate. '
      'Wear gloves and a mask. Observe the waiting period on the label before '
      'eating or selling. Keep treated produce and empty packets away from '
      'children and animals.';

  static const List<KnowledgeCard> cards = [
    // ---------------------------------------------------------------- Cassava
    KnowledgeCard(
      id: 'cassava_mosaic',
      crop: 'Cassava',
      title: 'Cassava mosaic disease',
      kind: CardKind.disease,
      symptoms:
          'Leaves show a patchy yellow-and-green or pale mosaic pattern. Leaves '
          'are twisted, curled, narrow and smaller than normal. Symptoms are '
          'clearest on young leaves at the shoot tip. Plants are stunted and '
          'roots are few and small. Caused by viruses spread by whiteflies and '
          'by planting cuttings from sick plants. Common wherever cassava is '
          'grown in Africa.',
      management:
          'Plant resistant or tolerant varieties from a trusted source. Take '
          'cuttings only from healthy plants with no mosaic. Pull out and '
          'destroy sick plants early, while they are young. Weed well. Do not '
          'plant new fields next to old, sick fields. Avoid moving cuttings '
          'from areas where the disease is severe. Ask your extension officer '
          'for clean planting material.',
    ),
    KnowledgeCard(
      id: 'cassava_bacterial_blight',
      crop: 'Cassava',
      title: 'Cassava bacterial blight',
      kind: CardKind.disease,
      symptoms:
          'Angular, water-soaked spots appear between leaf veins, then turn '
          'brown and join together. Leaves wilt, dry and fall, leaving bare '
          'shoot tips ("candlesticks"). Dark streaks form on young stems and '
          'leaf stalks, and sticky gum may ooze from stems. Shoot tips die back. '
          'Caused by Xanthomonas bacteria. Worse in the rainy season, spread by '
          'rain splash, tools and infected cuttings.',
      management:
          'Use clean cuttings from healthy fields and resistant varieties. Do '
          'not take cuttings from plants with stem gum or dieback. Rotate with '
          'cereals or legumes. Remove and burn infected plant debris. Avoid '
          'working in the field when plants are wet. Clean cutting tools between '
          'fields. Plant early in the rains so plants are strong before the '
          'peak wet period.',
    ),
    KnowledgeCard(
      id: 'cassava_brown_streak',
      crop: 'Cassava',
      title: 'Cassava brown streak disease',
      kind: CardKind.disease,
      symptoms:
          'Older leaves show yellow, feathery blotches along the side veins, '
          'while young leaves often look normal. Brown, dead streaks may appear '
          'on green stems. Roots may be pinched or cracked, and inside the flesh '
          'has dry, brown, corky patches, making them unfit to eat or sell. '
          'Caused by viruses spread by whiteflies and infected cuttings. Common '
          'in East, Central and Southern Africa.',
      management:
          'Plant tolerant varieties from certified, clean sources. Take cuttings '
          'only from fields with no leaf or root symptoms. Pull out and destroy '
          'plants with symptoms early. Harvest early in badly affected areas to '
          'limit root rot. Do not move cuttings between regions. If you see '
          'these symptoms in an area where the disease is not known, such as '
          'West Africa, report it to your extension officer at once.',
    ),
    KnowledgeCard(
      id: 'cassava_anthracnose',
      crop: 'Cassava',
      title: 'Cassava anthracnose disease',
      kind: CardKind.disease,
      symptoms: 'Sunken, dark brown cankers form on green stems and branches, '
          'especially near the shoot tip. Stems may become deformed and break. '
          'Shoot tips wilt and die back, and leaves drop. Old cankers on woody '
          'stems look like deep, rough wounds. Caused by a Colletotrichum '
          'fungus, often entering through bites of sap-sucking bugs. Worse in '
          'humid, rainy weather.',
      management:
          'Use cuttings only from healthy stems without cankers. Plant tolerant '
          'varieties. Remove and burn badly infected stems and plant debris. '
          'Rotate cassava with other crops. Plant at the start of the rains so '
          'plants grow strong early. Keep the field weeded to reduce humidity '
          'and bug pressure.',
    ),
    KnowledgeCard(
      id: 'cassava_root_rot',
      crop: 'Cassava',
      title: 'Cassava root rot',
      kind: CardKind.disease,
      symptoms: 'Plants wilt, leaves turn yellow and drop, and plants may die. '
          'Roots become soft, wet and rotten, with a bad smell, or dry, '
          'brown-black and crumbly. Rot often starts at the root tip or where '
          'roots were wounded. Caused by soil fungi such as Phytophthora, '
          'Fusarium and Lasiodiplodia. Worse in waterlogged or poorly drained '
          'soil and when harvest is delayed.',
      management: 'Plant on ridges or mounds in well-drained soil. Avoid low, '
          'waterlogged spots. Use healthy cuttings. Rotate with cereals or '
          'legumes for at least one season. Remove and destroy rotten roots '
          'and plants; do not leave them in the field. Do not delay harvest '
          'once roots are mature. Avoid wounding roots when weeding.',
    ),
    KnowledgeCard(
      id: 'cassava_green_mite',
      crop: 'Cassava',
      title: 'Cassava green mite',
      kind: CardKind.pest,
      symptoms: 'Young leaves at the shoot tip show many tiny yellow or white '
          'speckles. Leaves become small, pale, mottled and deformed. In severe '
          'attacks the shoot tip loses its leaves and looks like a bare '
          'candlestick. The mites are tiny green dots on the underside of young '
          'leaves, hard to see without a lens. Worst in the dry season.',
      management:
          'Plant tolerant varieties, especially hairy-leaved types. Plant early '
          'in the rains so plants are strong before the dry season. Protect '
          'natural enemies, especially predatory mites: avoid broad-spectrum '
          'insecticide sprays. Ask your extension officer about release of '
          'predatory mites. Use clean cuttings that carry no mites.',
    ),
    KnowledgeCard(
      id: 'cassava_mealybug',
      crop: 'Cassava',
      title: 'Cassava mealybug',
      kind: CardKind.pest,
      symptoms:
          'Shoot tips become bunched and crinkled, with short internodes, like '
          'a cabbage head ("bunchy top"). Small pink insects covered in white, '
          'waxy powder cluster on the shoot tips and under leaves. Leaves curl, '
          'yellow and drop. Stems may be thin and twisted. Worst in the dry '
          'season.',
      management:
          'Use clean cuttings without mealybugs. Protect natural enemies: a '
          'small parasitic wasp controls this pest well across Africa, so avoid '
          'broad-spectrum insecticides that kill it. Plant early in the rains. '
          'Mulch and add manure to help plants recover. Cut off and burn badly '
          'infested shoot tips.',
    ),

    // ------------------------------------------------------------------ Maize
    KnowledgeCard(
      id: 'maize_streak_virus',
      crop: 'Maize',
      title: 'Maize streak virus',
      kind: CardKind.disease,
      symptoms:
          'Young leaves show narrow, broken, pale yellow or white streaks '
          'running along the veins. Streaks may join so the whole leaf looks '
          'striped yellow. Plants infected young are badly stunted and produce '
          'small or no cobs. Caused by a virus spread by small leafhoppers that '
          'breed on grasses. Worse in late-planted maize.',
      management:
          'Plant streak-resistant or tolerant varieties. Sow early and at the '
          'same time as neighbours, with the first rains, to avoid peak '
          'leafhopper numbers. Control grassy weeds in and around the field. '
          'Remove volunteer maize and plants with early symptoms. Avoid '
          'planting new maize next to older maize.',
    ),
    KnowledgeCard(
      id: 'maize_leaf_blight',
      crop: 'Maize',
      title: 'Northern corn leaf blight',
      kind: CardKind.disease,
      symptoms:
          'Long, grey-green to tan, cigar-shaped spots form on the leaves, '
          'often several centimetres long. Spots start on lower leaves and move '
          'up. They may join and kill large areas of the leaf, so the plant '
          'looks burnt. Dark grey mould can form on spots in wet weather. Caused '
          'by the fungus Exserohilum turcicum. Favoured by humid weather and '
          'mild temperatures, common in highlands.',
      management:
          'Plant resistant varieties. Rotate maize with legumes or other '
          'non-grass crops. Bury or remove infected crop residue after harvest. '
          'Use balanced fertiliser. Spray a foliar fungicide, such as a '
          'triazole or strobilurin product where registered, only if disease '
          'appears early and is spreading fast on a valuable crop.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'maize_lethal_necrosis',
      crop: 'Maize',
      title: 'Maize lethal necrosis (MLN)',
      kind: CardKind.disease,
      symptoms:
          'Leaves show yellow mottling that starts at the base of young leaves. '
          'Leaves then dry from the edges inward. The central shoot may die '
          '("dead heart"). Plants are stunted and may die before tasselling. '
          'Cobs are small, deformed, with few or no grains. Caused by two '
          'viruses together, spread by thrips, aphids, beetles and seed. Mainly '
          'in East Africa.',
      management:
          'Plant MLN-tolerant varieties and certified seed only. Do not save '
          'seed from affected fields. Rotate with legumes, potato or other '
          'non-cereal crops. Do not grow maize all year round; keep a maize-free '
          'break. Pull out and destroy sick plants early. Control grassy weeds. '
          'MLN is serious: report suspected cases to your extension officer.',
    ),
    KnowledgeCard(
      id: 'maize_gray_leaf_spot',
      crop: 'Maize',
      title: 'Grey leaf spot',
      kind: CardKind.disease,
      symptoms:
          'Narrow, rectangular, grey to tan spots run along the leaf, with '
          'straight edges limited by the veins. Spots start on lower leaves and '
          'may join to kill whole leaves before the grain is filled. Caused by '
          'Cercospora fungi that survive in maize residue. Favoured by long '
          'periods of high humidity, warm days and continuous maize.',
      management:
          'Plant resistant or tolerant varieties. Rotate maize with legumes or '
          'other crops. Bury or remove maize residue. Avoid planting maize after '
          'maize. Use balanced fertiliser. A triazole or strobilurin fungicide '
          'where registered may pay on high-value fields if disease appears '
          'before tasselling.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'maize_common_rust',
      crop: 'Maize',
      title: 'Common rust',
      kind: CardKind.disease,
      symptoms:
          'Small, oval, raised pustules on both sides of the leaf. Pustules '
          'are cinnamon-brown to brick-red and release powdery spores that rub '
          'off on fingers. Pustules turn dark brown to black as the plant '
          'matures. Heavy attack yellows and dries leaves. Caused by the fungus '
          'Puccinia sorghi. Favoured by cool, humid weather, common in '
          'highlands.',
      management:
          'Plant resistant varieties; this is the main control. Plant early. '
          'Use balanced fertiliser. Remove volunteer maize. A fungicide is '
          'rarely worth it; consider a registered triazole or strobilurin '
          'product only on seed fields or high-value crops with early, severe '
          'infection.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'maize_ear_rot_aflatoxin',
      crop: 'Maize',
      title: 'Ear rot and aflatoxin',
      kind: CardKind.disease,
      symptoms:
          'Mould grows on the cob. Pink, red or white mould is often Fusarium. '
          'Green-yellow powdery mould is Aspergillus, which can make aflatoxin, '
          'a poison. White mould from the base with light, rotten cobs is '
          'Diplodia. Grains are discoloured or shrivelled. Worse after insect '
          'damage, drought, late harvest and wet storage. Aflatoxin may be '
          'present even when no mould is seen.',
      management:
          'Plant on time and control stem borers and armyworm to limit damage. '
          'Harvest as soon as the crop is mature. Dry cobs and grain quickly on '
          'tarpaulins or raised racks, never on bare soil. Sort out and destroy '
          'mouldy and damaged cobs. Store only dry grain, off the floor, in '
          'clean bags or hermetic bags. Ask about registered biocontrol '
          'products for aflatoxin. Never eat or feed mouldy grain.',
    ),
    KnowledgeCard(
      id: 'maize_downy_mildew',
      crop: 'Maize',
      title: 'Downy mildew',
      kind: CardKind.disease,
      symptoms:
          'Young plants show pale yellow or white stripes along the leaves. A '
          'white, downy growth appears under the leaves early in the morning. '
          'Leaves are narrow and stiff. Plants are stunted, and tassels may '
          'turn leafy and deformed ("crazy top"). Few or no cobs form. Caused '
          'by Peronosclerospora fungi. Spread from sorghum and other grasses. '
          'Worse in humid weather.',
      management:
          'Plant resistant varieties. Pull out and destroy infected plants as '
          'soon as seen. Avoid planting maize next to sorghum or wild sorghum '
          'grasses. Rotate with legumes. Buy seed already treated with a '
          'metalaxyl-type fungicide where registered, or treat seed according '
          'to the label.',
      safety: _seedTreatmentSafety,
    ),
    KnowledgeCard(
      id: 'fall_armyworm',
      crop: 'Maize',
      title: 'Fall armyworm',
      kind: CardKind.pest,
      symptoms:
          'Young leaves have small papery "windowpane" patches, then ragged '
          'holes in rows. Wet, sawdust-like droppings fill the funnel (whorl). '
          'Caterpillars hide in the whorl; they have a pale upside-down Y on '
          'the head and four dark spots in a square near the tail. Later they '
          'bore into cobs. Also attacks sorghum and millet.',
      management:
          'Scout twice a week from emergence. Crush egg masses and caterpillars '
          'by hand. Plant early and at the same time as neighbours. Intercrop '
          'with legumes or use push-pull with Desmodium and Brachiaria. Protect '
          'natural enemies. Use biopesticides such as Bt or virus products. If '
          'damage is high, apply an approved emamectin benzoate, spinetoram or '
          'chlorantraniliprole product into the whorl, where registered.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'maize_stem_borer',
      crop: 'Maize',
      title: 'Stem borers',
      kind: CardKind.pest,
      symptoms: 'Young leaves show rows of small round "shot holes" after they '
          'unroll. The central shoot may die ("dead heart"). Stems have entry '
          'holes with sawdust-like droppings and tunnels inside. Stems break and '
          'cobs may be bored. Caterpillars are pale, pink or cream, found inside '
          'stems. Several moth species. Also attacks sorghum, millet, rice and '
          'sugarcane.',
      management:
          'Use push-pull: Desmodium between rows and Napier or Brachiaria grass '
          'around the field. Plant early. Chop, burn or feed old stalks to '
          'animals after harvest to kill hiding larvae. Intercrop with legumes. '
          'Protect natural enemies, including parasitic wasps. If damage is '
          'severe, apply an approved insecticide into the whorl, where '
          'registered.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'stored_grain_weevils',
      crop: 'Maize',
      title: 'Grain weevils and larger grain borer',
      kind: CardKind.pest,
      symptoms:
          'Stored grain has small round holes, and fine flour-like dust builds '
          'up. Small brown or black beetles with a snout (weevils) crawl on '
          'grain. The larger grain borer is a small, dark, cylindrical beetle '
          'that turns cobs and grain into powder in a few months. Grain becomes '
          'light, hollow and warm. Also attacks sorghum, rice and dried '
          'cassava.',
      management:
          'Harvest on time and dry grain well before storage. Shell and clean '
          'grain, removing damaged grain. Clean the store and burn old residues '
          'before new harvest. Store in hermetic (airtight) bags or sealed '
          'containers. Keep bags off the floor and away from walls. If needed, '
          'use an approved grain storage protectant, where registered.',
      safety: _storageSafety,
    ),

    // ---------------------------------------------------------------- Sorghum
    KnowledgeCard(
      id: 'sorghum_anthracnose',
      crop: 'Sorghum',
      title: 'Sorghum anthracnose',
      kind: CardKind.disease,
      symptoms:
          'Small round or oval spots on the leaves with straw-coloured centres '
          'and red, purple or dark borders. Spots may join and kill the whole '
          'leaf. Tiny black dots form in the spot centres. The midrib may show '
          'long red lesions, and stalks can rot red inside. Caused by a '
          'Colletotrichum fungus. Favoured by warm, wet, humid weather.',
      management:
          'Plant resistant varieties. Rotate sorghum with legumes or other '
          'non-grass crops. Remove or bury crop residue after harvest. Control '
          'wild sorghum and grassy weeds. Use clean seed from healthy fields. '
          'Avoid very dense planting. '
          'Plant early so the crop matures before the wettest period. Use '
          'balanced fertiliser to keep plants strong.',
    ),
    KnowledgeCard(
      id: 'sorghum_covered_smut',
      crop: 'Sorghum',
      title: 'Covered kernel smut',
      kind: CardKind.disease,
      symptoms:
          'Some or all grains in the head are replaced by oval or cone-shaped '
          'grey-white sacs, larger than normal grain. Inside each sac is black '
          'powder (spores). Plants otherwise look normal. Caused by a fungus '
          'carried on the seed surface. Spores spread at threshing and stick to '
          'healthy seed.',
      management:
          'Use clean seed from healthy, smut-free heads. Cut and burn smutted '
          'heads before threshing. Do not save seed from affected fields. '
          'Rotate crops. Buy seed treated with a fungicide seed dressing, or '
          'treat seed according to the label, where registered.',
      safety: _seedTreatmentSafety,
    ),
    KnowledgeCard(
      id: 'sorghum_aphid',
      crop: 'Sorghum',
      title: 'Sugarcane aphid on sorghum',
      kind: CardKind.pest,
      symptoms:
          'Large colonies of small pale yellow to grey aphids on the underside '
          'of lower and middle leaves. Leaves become shiny and sticky with '
          'honeydew, then black with sooty mould. Leaves turn yellow, red or '
          'purple and dry out. Heads may fail to fill. Worse in dry weather.',
      management:
          'Plant tolerant varieties. Plant early. Scout the underside of leaves '
          'weekly. Protect ladybirds, lacewings and hoverflies, which eat '
          'aphids; avoid needless broad-spectrum sprays. If colonies spread '
          'fast across the field, apply an insecticide approved for aphids on '
          'sorghum, where registered.',
      safety: _spraySafety,
    ),

    // ----------------------------------------------------------------- Millet
    KnowledgeCard(
      id: 'millet_downy_mildew',
      crop: 'Millet',
      title: 'Downy mildew (green ear)',
      kind: CardKind.disease,
      symptoms:
          'Leaves of young pearl millet show pale yellow streaks, with white '
          'downy growth on the underside in humid mornings. Leaves later turn '
          'brown and split. Plants are stunted with many tillers. Heads turn '
          'into twisted, leafy green structures with no grain ("green ear"). '
          'Caused by Sclerospora graminicola, carried in soil and seed.',
      management:
          'Plant resistant varieties and clean seed. Pull out and burn infected '
          'plants early, before spores spread. Rotate millet with legumes or '
          'other crops. Buy seed treated with a metalaxyl-type fungicide, or '
          'treat seed according to the label, where registered. '
          'Do not save seed from infected fields.',
      safety: _seedTreatmentSafety,
    ),
    KnowledgeCard(
      id: 'millet_head_miner',
      crop: 'Millet',
      title: 'Millet head miner',
      kind: CardKind.pest,
      symptoms:
          'Pearl millet heads show spiral or winding lines of damaged, empty '
          'florets running around the head. Small caterpillars, pale to pink, '
          'feed under the flowers and grains, cutting flower stalks. Heads look '
          'patchy with missing grain. Common in the Sahel of West Africa.',
      management:
          'Plough after harvest to expose and kill the pupae in the soil. '
          'Ask your extension service about release of parasitic wasps, which '
          'have controlled this pest well in the Sahel. Protect natural enemies '
          'by avoiding broad-spectrum sprays. Use varieties suited to local '
          'planting dates.',
    ),

    // ------------------------------------------------------------------- Rice
    KnowledgeCard(
      id: 'rice_blast',
      crop: 'Rice',
      title: 'Rice blast',
      kind: CardKind.disease,
      symptoms:
          'Leaves show spindle- or diamond-shaped spots with grey or white '
          'centres and brown borders. Spots may join and kill leaves. At the '
          'neck below the panicle, a brown-black rot makes the panicle break '
          'or turn white with empty grain ("neck blast"). Caused by the fungus '
          'Magnaporthe oryzae. Favoured by humidity, cool nights and too much '
          'nitrogen.',
      management:
          'Plant resistant varieties and clean seed. Split nitrogen fertiliser '
          'into small doses; do not overuse it. Keep even flooding in lowland '
          'rice. Remove and burn infected straw. Avoid dense planting. Where '
          'neck blast is a known risk, a fungicide such as a tricyclazole or '
          'strobilurin product applied at booting, where registered, can help.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'rice_yellow_mottle_virus',
      crop: 'Rice',
      title: 'Rice yellow mottle virus',
      kind: CardKind.disease,
      symptoms:
          'Young leaves show yellow or orange mottling and streaks along the '
          'veins. Plants are stunted with fewer tillers. Flowering is late and '
          'panicles are small with many empty grains. Whole patches of the '
          'field may turn yellow. Caused by a virus spread by beetles, by '
          'contact during transplanting, and from old rice stubble. Found only '
          'in Africa.',
      management:
          'Plant resistant varieties. Destroy rice stubble, ratoons and '
          'volunteer rice after harvest. Plant at the same time as neighbours. '
          'Remove grassy weeds around fields. Pull out and bury infected plants '
          'early. Avoid handling seedlings roughly; transplant healthy '
          'seedlings only. '
          'Clean tools and hands after handling sick plants.',
    ),
    KnowledgeCard(
      id: 'rice_bacterial_leaf_blight',
      crop: 'Rice',
      title: 'Bacterial leaf blight',
      kind: CardKind.disease,
      symptoms:
          'Water-soaked stripes start at the leaf tips or edges and spread '
          'down the leaf. They turn yellow then grey-white, with a wavy edge. '
          'Drops of milky or yellow ooze may form on young spots in the '
          'morning. Seedlings may wilt and die ("kresek"). Caused by Xanthomonas '
          'bacteria, spread by water, wind and rain. Worse with high nitrogen.',
      management:
          'Plant resistant varieties and clean seed. Use balanced fertiliser; '
          'avoid too much nitrogen. Do not cut the tips of seedlings at '
          'transplanting. Drain fields when disease starts, if possible. '
          'Destroy infected stubble and weeds. Keep bunds and channels clean. '
          'Do not let water flow from infected fields into healthy ones.',
    ),
    KnowledgeCard(
      id: 'rice_brown_spot',
      crop: 'Rice',
      title: 'Brown spot',
      kind: CardKind.disease,
      symptoms:
          'Oval, brown spots with grey or pale centres, about the size of a '
          'sesame seed, scattered over the leaves. Grains show dark brown '
          'spots and may be empty or light. Seedlings may die. Caused by the '
          'fungus Bipolaris oryzae. Mostly a sign of poor soil, especially low '
          'potassium, and drought stress.',
      management: 'Improve soil fertility with balanced fertiliser, especially '
          'potassium, plus manure or compost. Use clean seed from healthy '
          'fields. Keep water supply even and avoid drought stress. Plant '
          'tolerant varieties. Remove infected straw and weeds. '
          'Return rice straw or ash to the field to give back potassium. '
          'Plant at the right time for your area.',
    ),
    KnowledgeCard(
      id: 'rice_gall_midge',
      crop: 'Rice',
      title: 'African rice gall midge',
      kind: CardKind.pest,
      symptoms:
          'Instead of a normal leaf, a tiller forms a long, hollow, pale tube '
          'that looks like an onion leaf ("silver shoot" or "onion leaf"). '
          'Affected tillers produce no panicle. Many tubes in a hill cut yield '
          'sharply. Caused by the maggot of a small fly. Worse in the rainy '
          'season and with late planting.',
      management:
          'Plant resistant varieties. Plant early and at the same time as '
          'neighbours. Destroy ratoons, volunteer rice and wild rice after '
          'harvest. Avoid too much nitrogen. Protect natural enemies, '
          'especially small parasitic wasps; avoid broad-spectrum sprays. '
          'Remove grassy weeds on bunds. Avoid planting next to late-planted '
          'fields.',
    ),

    // -------------------------------------------------------------------- Yam
    KnowledgeCard(
      id: 'yam_anthracnose',
      crop: 'Yam',
      title: 'Yam anthracnose (leaf scorch)',
      kind: CardKind.disease,
      symptoms:
          'Small dark brown to black spots on leaves, often with a yellow halo. '
          'Spots join and leaves turn black, dry and look scorched. Vines turn '
          'black and die back from the tips. Whole plants may die early, giving '
          'small tubers. Caused by a Colletotrichum fungus. Worse in the rainy '
          'season. Water yam is very susceptible.',
      management:
          'Plant tolerant varieties and healthy seed yams. Stake vines to lift '
          'leaves off the ground. Rotate with cereals or legumes. Remove and '
          'burn infected vines and debris. Plant early so plants are strong '
          'before peak rains. If the disease is severe, a protectant fungicide '
          'such as a mancozeb or copper product, where registered, can slow it.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'yam_mosaic_virus',
      crop: 'Yam',
      title: 'Yam mosaic virus',
      kind: CardKind.disease,
      symptoms:
          'Leaves show a light and dark green mosaic, mottling or green bands '
          'along the veins. Leaves may be small, wavy, twisted or strap-like. '
          'Plants are stunted and vines are weak, giving fewer and smaller '
          'tubers. Caused by viruses spread by aphids and, above all, by '
          'planting infected seed yams.',
      management:
          'Plant clean seed yams from certified sources or from healthy, '
          'symptom-free plants. Mark healthy plants in the field and keep '
          'their tubers for seed. Pull out and destroy plants with symptoms '
          'early. Weed well. Plant tolerant varieties where available. '
          'Do not take seed yams from fields with many sick plants.',
    ),
    KnowledgeCard(
      id: 'yam_nematodes',
      crop: 'Yam',
      title: 'Yam nematodes and dry rot',
      kind: CardKind.pest,
      symptoms:
          'Tuber skin is cracked and flaky. Just under the skin the flesh has '
          'dry, brown to black rot ("dry rot") that gets worse in storage. '
          'Other tubers have knobby lumps and galls, or are split and '
          'deformed. Leaves may look normal. Caused by tiny soil worms '
          '(nematodes) carried in seed yams and soil.',
      management:
          'Plant only clean, healthy seed yams with no cracks or dark patches. '
          'Peel and inspect seed yam pieces before planting. Ask your extension '
          'officer about hot-water treatment of seed yams. Rotate yam with '
          'cereals or grass fallow. Sort tubers at harvest and store only '
          'healthy ones.',
    ),

    // ---------------------------------------------------------------- Cocoyam
    KnowledgeCard(
      id: 'cocoyam_leaf_blight',
      crop: 'Cocoyam',
      title: 'Taro leaf blight',
      kind: CardKind.disease,
      symptoms:
          'Small water-soaked spots on taro leaves grow quickly into large, '
          'round purple-brown blotches with yellow edges. Orange or yellow '
          'droplets ooze from the spots, and white powdery growth forms at the '
          'edges. Leaves rot and collapse within days. Corms are small. Caused '
          'by Phytophthora colocasiae. Worse in warm, wet, humid weather.',
      management:
          'Plant tolerant varieties and clean planting material. Remove and '
          'destroy infected leaves early. Space plants wider to let air pass. '
          'Rotate with other crops. Do not bring planting material from '
          'affected areas. Where registered, a copper or metalaxyl-type '
          'fungicide can protect leaves during wet periods.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'cocoyam_root_rot',
      crop: 'Cocoyam',
      title: 'Cocoyam root rot',
      kind: CardKind.disease,
      symptoms:
          'Leaves of tannia (new cocoyam) turn yellow, wilt and die early. '
          'Plants are stunted with few, small cormels. Roots are brown, soft '
          'and rotten, with few healthy white roots. Caused by the soil fungus '
          'Pythium myriotylum. Worse in wet, poorly drained soil and where '
          'cocoyam is grown year after year.',
      management:
          'Use clean, healthy planting material. Plant on raised beds or '
          'ridges in well-drained soil. Rotate with cereals or other crops. '
          'Add compost or manure to improve soil. Remove and destroy sick '
          'plants. Do not plant cocoyam in fields with a history of root rot.',
    ),

    // ----------------------------------------------------------- Sweet potato
    KnowledgeCard(
      id: 'sweet_potato_virus_disease',
      crop: 'Sweet potato',
      title: 'Sweet potato virus disease',
      kind: CardKind.disease,
      symptoms:
          'Plants are badly stunted. Leaves are small, narrow, wrinkled and '
          'twisted, with pale or yellow mottling and cleared veins. Some '
          'leaves show purple patches. Vines are short and bushy. Few and '
          'small roots form. Caused by two viruses together, spread by aphids, '
          'whiteflies and infected vine cuttings.',
      management:
          'Take vine cuttings only from healthy, vigorous plants with no '
          'symptoms, or buy clean vines from trusted multipliers. Pull out and '
          'destroy sick plants early. Plant new fields away from old sweet '
          'potato fields. Plant tolerant varieties. '
          'Weed well and remove volunteer sweet potato plants from old '
          'fields.',
    ),
    KnowledgeCard(
      id: 'sweet_potato_weevil',
      crop: 'Sweet potato',
      title: 'Sweet potato weevil',
      kind: CardKind.pest,
      symptoms:
          'Roots have small holes and tunnels filled with droppings. Damaged '
          'roots are spongy, have a bad smell and taste bitter. Vine bases may '
          'be swollen and cracked. Adults are small, ant-like weevils with a '
          'blue-black body and orange-red middle. Worse in dry seasons when the '
          'soil cracks.',
      management:
          'Use clean vine tops, not the base, for planting. Hill up soil and '
          'fill cracks around plants. Water if possible in dry spells. Harvest '
          'on time; do not leave roots in the ground. Remove and destroy crop '
          'debris and leftover roots. Rotate fields and plant away from old '
          'sweet potato fields.',
    ),

    // ----------------------------------------------------------------- Potato
    KnowledgeCard(
      id: 'potato_late_blight',
      crop: 'Potato',
      title: 'Potato late blight',
      kind: CardKind.disease,
      symptoms:
          'Dark brown to black, water-soaked patches on leaves, often starting '
          'at the edges. White mould forms on the underside in humid mornings. '
          'Stems get dark lesions. The whole field can collapse in days. '
          'Tubers show reddish-brown, firm rot under the skin. Caused by '
          'Phytophthora infestans. Favoured by cool, wet, misty weather.',
      management:
          'Plant certified seed and resistant varieties. Hill up soil well '
          'over tubers. Remove volunteer potatoes and cull piles. Start '
          'spraying a protectant fungicide such as a mancozeb product before '
          'symptoms in wet weather. Use a registered systemic product when '
          'blight is active, and rotate product groups. Cut and remove haulms '
          'before harvest if infected.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'potato_bacterial_wilt',
      crop: 'Potato',
      title: 'Potato bacterial wilt',
      kind: CardKind.disease,
      symptoms:
          'Plants wilt suddenly while leaves are still green, first in the heat '
          'of the day. Plants then die. Cut tubers show a brown ring, and a '
          'creamy ooze comes out of the ring or the eyes. Soil sticks to the '
          'eyes. Caused by Ralstonia bacteria carried in seed tubers, soil and '
          'water. Also attacks tomato, pepper and eggplant.',
      management:
          'Plant certified, disease-free seed. Rotate for several seasons with '
          'cereals or other non-host crops; avoid tomato, pepper and eggplant. '
          'Remove wilted plants with their tubers and soil. Do not irrigate '
          'from infected fields. Clean tools and boots. Report severe outbreaks '
          'to your extension officer.',
    ),

    // ----------------------------------------------------------------- Cowpea
    KnowledgeCard(
      id: 'cowpea_pod_borer',
      crop: 'Cowpea',
      title: 'Legume pod borer (Maruca)',
      kind: CardKind.pest,
      symptoms:
          'Flowers, buds and pods are webbed together with silk. Pods have '
          'small round holes with droppings. Flowers drop and few pods form. '
          'Caterpillars are pale or greenish with dark spots in rows on the '
          'body. Attacks cowpea, pigeon pea, beans and soybean, mainly at '
          'flowering.',
      management:
          'Plant early and intercrop with cereals. Scout flowers twice a week. '
          'Spray neem seed extract or a Bt or virus biopesticide at the start '
          'of flowering. Plant approved pest-resistant (Bt) cowpea varieties '
          'where available. If damage is heavy, apply an insecticide approved '
          'for pod borer on cowpea, where registered, at flowering.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'cowpea_flower_thrips',
      crop: 'Cowpea',
      title: 'Flower thrips',
      kind: CardKind.pest,
      symptoms:
          'Flower buds turn brown, dry up and fall before opening. Flowers are '
          'distorted and discoloured. Few pods form, even on healthy-looking '
          'plants. Tiny, slender, dark insects can be seen inside flowers when '
          'shaken onto white paper. Worse in dry weather.',
      management:
          'Plant tolerant varieties. Plant early. Intercrop with cereals. '
          'Spray neem seed extract at budding. Remove weed hosts near the '
          'field. If many buds are dropping, apply an insecticide approved for '
          'thrips on cowpea, where registered, at the bud stage. '
          'Rotate cowpea with cereals.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'legume_bruchids',
      crop: 'Many crops',
      title: 'Bruchids in stored beans and cowpea',
      kind: CardKind.pest,
      symptoms:
          'Stored beans or cowpea seeds have small, round, clean exit holes. '
          'Tiny white eggs may be stuck on seeds. Small brown, oval beetles '
          'appear on the grain and in the bag. Seeds turn to powder and lose '
          'weight. Infestation often starts in the field on dry pods and grows '
          'fast in storage.',
      management:
          'Harvest on time and dry seeds well. Sort out damaged seeds. Store in '
          'hermetic (airtight) bags or sealed containers; lack of air kills the '
          'beetles. Clean stores before the new harvest. Solar drying of grain '
          'helps kill eggs. Mixing with clean dry ash or vegetable oil is a '
          'traditional protectant for small amounts.',
    ),

    // ------------------------------------------------------------ Common bean
    KnowledgeCard(
      id: 'bean_angular_leaf_spot',
      crop: 'Common bean',
      title: 'Angular leaf spot',
      kind: CardKind.disease,
      symptoms:
          'Grey to brown spots with sharp, angular edges limited by the leaf '
          'veins, giving a checkerboard look. Dark grey fuzz forms on the '
          'underside of spots. Leaves yellow and drop early. Pods show '
          'reddish-brown round spots. Caused by a fungus carried on seed and '
          'crop residue. Favoured by warm, wet weather.',
      management:
          'Plant resistant varieties and clean, certified seed. Rotate beans '
          'with cereals for at least one season. Remove or bury bean residue '
          'after harvest. Avoid working in the field when plants are wet. Do '
          'not save seed from infected pods. '
          'Space plants for airflow.',
    ),
    KnowledgeCard(
      id: 'bean_anthracnose',
      crop: 'Common bean',
      title: 'Bean anthracnose',
      kind: CardKind.disease,
      symptoms:
          'Dark red-brown to black lines along the veins on the underside of '
          'leaves. Pods have round, sunken, dark brown spots with a pale centre '
          'and dark rim. Seeds may be stained. Stems may have dark sunken '
          'cankers. Caused by a Colletotrichum fungus carried in seed. Favoured '
          'by cool, wet weather, common in highlands.',
      management:
          'Use certified, clean seed and resistant varieties. Never plant seed '
          'from spotted pods. Rotate beans with cereals. Remove and burn '
          'infected debris. Do not walk through the crop when leaves are wet. '
          'Do not save seed from infected fields. Plant at the right time for '
          'your area.',
    ),
    KnowledgeCard(
      id: 'bean_rust',
      crop: 'Common bean',
      title: 'Bean rust',
      kind: CardKind.disease,
      symptoms: 'Small, raised, reddish-brown powdery pustules, mostly on the '
          'underside of leaves, often with a yellow halo. Powder rubs off on '
          'fingers. Heavy attack yellows leaves and they drop early. Pods may '
          'also show pustules. Caused by the fungus Uromyces appendiculatus. '
          'Favoured by humid weather with mild days.',
      management:
          'Plant resistant varieties. Rotate with cereals and remove bean '
          'residue after harvest. Avoid planting new beans next to infected '
          'older beans. Space plants for airflow. If rust starts before '
          'flowering, a fungicide such as a triazole product where registered '
          'can protect yield.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'bean_common_mosaic',
      crop: 'Common bean',
      title: 'Bean common mosaic',
      kind: CardKind.disease,
      symptoms:
          'Leaves show light and dark green mosaic, puckering and blistering. '
          'Leaves curl downward and are narrow and long. Plants are stunted '
          'with few pods. Some varieties show sudden wilting, black veins and '
          'death ("black root"). Caused by viruses carried in seed and spread '
          'by aphids.',
      management:
          'Use certified seed and resistant varieties. Do not save seed from '
          'sick plants. Pull out and destroy plants with symptoms early. '
          'Control weeds. Plant bean fields away from older infected bean '
          'fields. '
          'Protect natural enemies of aphids. Plant early to avoid peak aphid '
          'numbers.',
    ),
    KnowledgeCard(
      id: 'bean_stem_maggot',
      crop: 'Common bean',
      title: 'Bean stem maggot (bean fly)',
      kind: CardKind.pest,
      symptoms:
          'Young bean plants turn yellow, wilt and die, often in patches. The '
          'stem base is swollen and cracked just above the soil. Inside are '
          'small white maggots or brown pupae under the skin. Leaves show tiny '
          'pale feeding spots. Worse in dry weather and late plantings.',
      management:
          'Plant early with the first rains. Hill up soil around the stem base '
          'to help new roots grow. Use manure and fertiliser to keep plants '
          'vigorous. Plant tolerant varieties. Where the pest is common, use '
          'seed treated with an approved insecticide, where registered.',
      safety: _seedTreatmentSafety,
    ),

    // -------------------------------------------------------------- Groundnut
    KnowledgeCard(
      id: 'groundnut_rosette',
      crop: 'Groundnut',
      title: 'Groundnut rosette',
      kind: CardKind.disease,
      symptoms: 'Plants are severely stunted and bushy, with many small leaves '
          'crowded at the top. In chlorotic rosette, leaves are yellow with '
          'green veins or mottled. In green rosette, leaves are dark green and '
          'small. Few or no pods form if infected young. Caused by a virus '
          'complex spread by groundnut aphids.',
      management:
          'Plant resistant varieties. Plant early with the first rains. Plant '
          'at close spacing; dense crops get fewer aphids. Pull out and destroy '
          'infected plants early. Remove volunteer groundnut. Plant at the same '
          'time as neighbours. '
          'Do not plant late; late crops suffer most.',
    ),
    KnowledgeCard(
      id: 'groundnut_leaf_spot',
      crop: 'Groundnut',
      title: 'Early and late leaf spot',
      kind: CardKind.disease,
      symptoms:
          'Round spots on leaves. Early leaf spot: light brown spots, often '
          'with a yellow halo, clearest on the upper surface. Late leaf spot: '
          'dark brown to black spots, clearest on the underside. Leaves fall '
          'early, leaving bare stems and fewer pods. Caused by Cercospora-type '
          'fungi. Favoured by humid, warm weather.',
      management:
          'Plant resistant varieties. Rotate groundnut with cereals. Remove or '
          'bury crop residue and volunteer plants. Plant early. Where disease is '
          'severe every year, a fungicide such as a chlorothalonil, triazole or '
          'mancozeb product, where registered, sprayed from first spots, can '
          'protect yield.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'groundnut_rust',
      crop: 'Groundnut',
      title: 'Groundnut rust',
      kind: CardKind.disease,
      symptoms:
          'Small orange to reddish-brown powdery pustules on the underside of '
          'leaves. Matching yellow spots show on the upper side. Leaves dry and '
          'die but often stay attached to the plant. Pods are small and fewer. '
          'Caused by the fungus Puccinia arachidis. Favoured by humid weather. '
          'Often seen together with leaf spots.',
      management:
          'Plant rust-resistant varieties. Plant early. Destroy volunteer '
          'groundnut plants between seasons. Rotate with cereals. Where rust is '
          'severe, a fungicide approved for groundnut rust, where registered, '
          'can protect yield. '
          'Space plants for airflow. Use clean seed from healthy fields. '
          'Avoid planting next to older infected fields.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'groundnut_aflatoxin',
      crop: 'Groundnut',
      title: 'Aflatoxin mould',
      kind: CardKind.disease,
      symptoms:
          'Kernels show yellow-green or olive powdery mould, or are shrivelled '
          'and discoloured. Black mould at the base of seedlings can cause '
          'collar rot. The mould Aspergillus flavus can make aflatoxin, a '
          'poison that harms people and animals. Worse with drought at pod '
          'filling, damaged pods, late harvest and wet storage. Aflatoxin may '
          'be present without visible mould.',
      management:
          'Plant on time and avoid drought stress at pod filling. Apply gypsum '
          'or lime at flowering where advised. Harvest when mature, without '
          'damaging pods. Dry pods quickly on tarpaulins, never on bare soil. '
          'Sort out and destroy mouldy, broken and shrivelled nuts. Store dry, '
          'off the floor, in clean bags. Ask about registered biocontrol '
          'products for aflatoxin. Never eat or sell mouldy nuts.',
    ),

    // ---------------------------------------------------------------- Soybean
    KnowledgeCard(
      id: 'soybean_rust',
      crop: 'Soybean',
      title: 'Soybean rust',
      kind: CardKind.disease,
      symptoms: 'Tiny angular grey-green spots on lower leaves turn tan or '
          'reddish-brown. Small raised pustules on the underside release '
          'light-coloured powder. Leaves turn yellow and fall early, from the '
          'bottom up. Pods are fewer with small seeds. Caused by the fungus '
          'Phakopsora pachyrhizi. Favoured by long wet periods and mild '
          'temperatures.',
      management:
          'Plant tolerant or resistant varieties. Plant early so pods fill '
          'before peak disease. Remove volunteer soybean. Scout lower leaves '
          'from flowering. If rust appears before pod fill, spray a triazole '
          'or strobilurin fungicide where registered. '
          'Rotate with cereals. Use balanced fertiliser.',
      safety: _spraySafety,
    ),

    // ------------------------------------------------------- Banana / plantain
    KnowledgeCard(
      id: 'banana_xanthomonas_wilt',
      crop: 'Banana',
      title: 'Banana Xanthomonas wilt (BXW)',
      kind: CardKind.disease,
      symptoms:
          'Leaves turn yellow and wilt. The male bud shrivels and turns black. '
          'Fruit ripens early and unevenly, and inside has rusty brown stains. '
          'Cut stems release a yellow, sticky ooze within minutes. Plants die. '
          'Caused by bacteria spread by insects visiting male flowers, dirty '
          'tools and infected suckers. Affects banana and plantain in East and '
          'Central Africa.',
      management:
          'Remove the male bud with a forked stick once the last hand forms. '
          'Cut out sick stems at soil level and leave them to rot or bury them. '
          'Disinfect tools with fire or household bleach after each plant. Use '
          'clean suckers from healthy fields. Do not move planting material or '
          'leaves from affected areas. Report outbreaks to your extension '
          'officer.',
    ),
    KnowledgeCard(
      id: 'banana_bunchy_top',
      crop: 'Banana',
      title: 'Banana bunchy top (BBTV)',
      kind: CardKind.disease,
      symptoms:
          'Dark green dots and dashes ("Morse code" streaks) along the leaf '
          'veins and stalks. New leaves are narrow, short, stiff, upright and '
          'bunched at the top. Leaf edges turn yellow and wavy. Plants are '
          'stunted and give no bunch. Caused by a virus spread by the banana '
          'aphid and infected suckers.',
      management: 'Plant clean suckers or tissue-culture plants from certified '
          'sources. Dig out and destroy the whole mat of infected plants, '
          'including the corm and suckers. Do not move suckers from affected '
          'areas. Check fields often and remove new cases quickly. BBTV is '
          'serious: report it to your extension officer.',
    ),
    KnowledgeCard(
      id: 'banana_black_sigatoka',
      crop: 'Banana',
      title: 'Black Sigatoka (black leaf streak)',
      kind: CardKind.disease,
      symptoms:
          'Small reddish-brown streaks on the underside of leaves, running '
          'along the veins. They turn black and grow into oval spots with grey '
          'centres and yellow halos. Large parts of the leaf die. Plants have '
          'few healthy leaves at bunching, so bunches are small and ripen '
          'early. Caused by a fungus. Favoured by rain and humidity.',
      management:
          'Cut off and remove badly spotted leaves or leaf parts regularly. '
          'Remove extra suckers and keep good spacing for airflow. Drain wet '
          'fields. Use manure for strong plants. Plant tolerant varieties. In '
          'commercial plantings, a registered fungicide programme, rotating '
          'product groups, may be needed.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'banana_fusarium_wilt',
      crop: 'Banana',
      title: 'Fusarium wilt (Panama disease)',
      kind: CardKind.disease,
      symptoms:
          'Older leaves turn yellow from the edges, then wilt and hang down '
          'around the stem like a skirt. The base of the pseudostem may split. '
          'Cutting the pseudostem or corm shows red-brown to purple streaks and '
          'dots inside. Plants die. Caused by a soil fungus that survives for '
          'decades. A new strain, TR4, attacks Cavendish bananas.',
      management: 'There is no cure. Plant resistant varieties and clean, '
          'tissue-culture plants. Do not move soil, suckers or plant parts from '
          'affected farms. Clean tools and boots. Dig out sick plants and leave '
          'the spot unplanted with bananas. Report suspected cases to your '
          'extension officer, especially wilting Cavendish, as it may be TR4.',
    ),
    KnowledgeCard(
      id: 'banana_weevil',
      crop: 'Banana',
      title: 'Banana weevil',
      kind: CardKind.pest,
      symptoms: 'Plants are weak with small bunches. They snap or fall over, '
          'especially when carrying a bunch. Cutting the corm shows round '
          'tunnels filled with brown, rotting tissue. Adults are hard, black '
          'beetles with a snout, hiding near the base. Larvae are white, '
          'legless grubs inside the corm.',
      management:
          'Plant clean suckers: pare off roots and outer corm until clean '
          'white tissue shows. Chop old stems after harvest into small pieces '
          'and spread them to dry. Trap adults with split pseudostem pieces '
          'laid near plants and destroy the weevils daily. Mulch and manure '
          'for vigorous plants.',
    ),
    KnowledgeCard(
      id: 'banana_nematodes',
      crop: 'Banana',
      title: 'Banana root nematodes',
      kind: CardKind.pest,
      symptoms: 'Plants topple over with the roots still attached, often when '
          'carrying a bunch. Roots are few, short, with dark red-brown to black '
          'patches and rot. Bunches are small and growth is slow. Caused by '
          'tiny soil worms (nematodes) spread with infected suckers.',
      management:
          'Plant tissue-culture plants or pared, clean suckers. Ask your '
          'extension officer about hot-water treatment of suckers. Plant in new '
          'land or after a fallow or rotation with non-host crops. Mulch and '
          'add manure to support roots. Prop heavy plants with poles.',
    ),

    // ------------------------------------------------------------------ Cocoa
    KnowledgeCard(
      id: 'cocoa_black_pod',
      crop: 'Cocoa',
      title: 'Black pod disease',
      kind: CardKind.disease,
      symptoms:
          'A small brown spot appears on the pod, often at the tip or base, '
          'and spreads fast until the whole pod is chocolate-brown to black. '
          'White mould may cover the pod in wet weather. Beans inside rot. '
          'Cankers may form on the trunk. Caused by Phytophthora fungi. Worse '
          'in the rainy season, with heavy shade and poor drainage.',
      management:
          'Harvest ripe pods often. Remove and bury or burn black pods every '
          'week; do not leave them on trees or the ground. Prune trees and '
          'shade trees for airflow and light. Weed and drain the farm. Where '
          'registered, spray a copper fungicide or a metalaxyl-copper product '
          'on pods in the rainy season.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'cocoa_swollen_shoot',
      crop: 'Cocoa',
      title: 'Cocoa swollen shoot virus (CSSV)',
      kind: CardKind.disease,
      symptoms:
          'Young flush leaves show red bands along the veins. Older leaves '
          'show yellow vein-banding, flecks or mosaic. Swellings form on shoots, '
          'stems and roots. Pods may be small and round. Leaves fall and trees '
          'die within a few years. Caused by a virus spread by mealybugs. '
          'Major problem in Ghana, Côte d\'Ivoire, Togo and Nigeria.',
      management:
          'There is no cure. Report suspected trees to your extension officer '
          'or cocoa board, who may cut out infected and nearby trees. Replant '
          'with tolerant varieties from approved nurseries. Plant barrier '
          'crops between old and new farms where advised. Do not move budwood '
          'or seedlings from affected areas.',
    ),
    KnowledgeCard(
      id: 'cocoa_mirids',
      crop: 'Cocoa',
      title: 'Cocoa mirids (capsids)',
      kind: CardKind.pest,
      symptoms:
          'Small dark, round or oval sunken spots on pods and young green '
          'shoots where bugs feed. Shoots wilt and die back, leaving dead, '
          'leafless branches ("mirid blast"). Cankers form on stems. Trees in '
          'gaps in the canopy are worst. The bugs are brown or reddish, about '
          'one centimetre long.',
      management:
          'Keep an even canopy with light shade; fill gaps. Check trees '
          'regularly, especially in open areas. Remove dead branches. Follow '
          'the national cocoa spraying programme. Where needed, use an '
          'insecticide approved for mirids on cocoa, at the time advised by '
          'your extension service.',
      safety: _spraySafety,
    ),

    // ----------------------------------------------------------------- Coffee
    KnowledgeCard(
      id: 'coffee_berry_disease',
      crop: 'Coffee',
      title: 'Coffee berry disease (CBD)',
      kind: CardKind.disease,
      symptoms:
          'Dark, sunken spots on green berries spread until the berry turns '
          'black and shrivels. Black, dry berries stay on the branch '
          '("mummies"). Flowers may show brown streaks. Pinkish spore masses '
          'can form on spots. Caused by the fungus Colletotrichum kahawae. '
          'Affects Arabica coffee in highland Africa during wet weather.',
      management:
          'Plant resistant varieties. Prune to open the bush and remove old '
          'wood. Pick and destroy infected and mummified berries. Where the '
          'disease is common, spray a copper fungicide or other registered '
          'product from flowering through the wet season, following extension '
          'advice.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'coffee_leaf_rust',
      crop: 'Coffee',
      title: 'Coffee leaf rust',
      kind: CardKind.disease,
      symptoms:
          'Pale yellow spots on the upper side of leaves. On the underside, '
          'matching spots are covered in bright orange-yellow powder. Spots '
          'grow and join. Leaves fall early, branches become bare, and the next '
          'crop is reduced. Caused by the fungus Hemileia vastatrix. Favoured '
          'by warm, wet weather and heavy crops.',
      management:
          'Plant resistant varieties. Prune for airflow and remove suckers. '
          'Use balanced fertiliser and manure. Keep light shade. Where rust is '
          'serious, a copper fungicide or a registered triazole product, '
          'applied at the start of the rains, can protect leaves. '
          'Remove fallen infected leaves.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'coffee_wilt_disease',
      crop: 'Coffee',
      title: 'Coffee wilt disease',
      kind: CardKind.disease,
      symptoms:
          'Leaves turn yellow, curl, dry and fall, starting on one branch or '
          'side. Berries ripen early and dry on the branch. Peeling the bark at '
          'the stem base shows blue-black streaks in the wood. The whole tree '
          'dies within months. Caused by a Fusarium fungus. Mainly Robusta in '
          'Uganda, DR Congo and Tanzania.',
      management:
          'There is no cure. Uproot sick trees with roots and burn them on the '
          'spot; do not carry them across the farm. Disinfect tools with fire '
          'after use. Do not replant coffee in the same spot soon. Replant with '
          'resistant clones from approved nurseries. Report cases to your '
          'extension officer.',
    ),
    KnowledgeCard(
      id: 'coffee_berry_borer',
      crop: 'Coffee',
      title: 'Coffee berry borer',
      kind: CardKind.pest,
      symptoms:
          'Green and ripe berries have a small round hole at the tip (the end '
          'opposite the stalk). Inside, the beans have tunnels and tiny white '
          'larvae. Damaged berries may fall early. Beans are light and '
          'low-grade. Adults are tiny black beetles.',
      management:
          'Pick all ripe berries regularly. At the end of the season, strip '
          'all remaining berries and collect fallen ones; destroy damaged '
          'berries. Dry harvested coffee quickly. Prune for light and airflow. '
          'Use alcohol-baited traps where advised. Ask about Beauveria fungus '
          'biopesticide where registered.',
    ),

    // -------------------------------------------------------------------- Tea
    KnowledgeCard(
      id: 'tea_root_rot',
      crop: 'Tea',
      title: 'Armillaria root rot',
      kind: CardKind.disease,
      symptoms:
          'Tea bushes wilt, leaves turn yellow then brown, and the bush dies '
          'suddenly, often in a spreading patch. Under the bark at the collar '
          'and roots there are white, fan-shaped sheets of fungus with a '
          'mushroom smell. Black bootlace-like strands may grow on roots. '
          'Common where tea was planted after forest clearing.',
      management:
          'Dig out dead and dying bushes with all roots, and burn them. Remove '
          'old tree stumps and roots from the field. Leave the patch under '
          'grass fallow before replanting where advised. Before clearing '
          'forest for tea, ring-bark trees so roots die and lose food. Ask your '
          'extension officer for advice.',
    ),

    // ----------------------------------------------------------------- Cotton
    KnowledgeCard(
      id: 'cotton_bacterial_blight',
      crop: 'Cotton',
      title: 'Bacterial blight (blackarm)',
      kind: CardKind.disease,
      symptoms:
          'Angular, water-soaked spots between veins on leaves, turning brown '
          'to black. Black lesions spread along veins. Stems and branches get '
          'long black cankers and may break ("blackarm"). Bolls show round, '
          'dark, sunken spots and rot. Caused by Xanthomonas bacteria carried '
          'on seed. Worse after rain storms.',
      management:
          'Plant resistant varieties and clean, delinted seed from an approved '
          'source. Rotate cotton with cereals. Plough under or burn crop '
          'residue after harvest. Remove volunteer cotton. '
          'Avoid working in the field when plants are wet. Plant at the right '
          'time for your area. Do not save seed from infected fields.',
    ),
    KnowledgeCard(
      id: 'cotton_jassids',
      crop: 'Cotton',
      title: 'Cotton jassids (leafhoppers)',
      kind: CardKind.pest,
      symptoms: 'Leaf edges turn yellow, then red or brown, and curl downward. '
          'Leaves look burnt ("hopperburn") and drop. Small, pale green, '
          'wedge-shaped insects run sideways on the underside of leaves. Plants '
          'are stunted. Smooth-leaved varieties suffer most. '
          'Turn leaves over to see them.',
      management:
          'Plant hairy-leaved, jassid-tolerant varieties; this is the main '
          'control. Plant at the right time for your area. Keep plants healthy '
          'with balanced fertiliser. Protect natural enemies. Scout weekly and '
          'follow extension spray thresholds, using only approved '
          'insecticides, where registered. '
          'Remove weed hosts near the field.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'cotton_stainers',
      crop: 'Cotton',
      title: 'Cotton stainers',
      kind: CardKind.pest,
      symptoms:
          'Bright red-and-black bugs cluster on open bolls and seeds. They '
          'suck the seeds, and the lint becomes stained yellow or brown. Bolls '
          'may rot and seeds are light. Also found on okra, baobab and kapok '
          'trees. '
          'Young bugs are smaller, bright red and wingless.',
      management:
          'Pick seed cotton promptly as bolls open. Destroy crop residue after '
          'harvest. Remove alternative host plants near the field where '
          'practical. Collect and destroy bug clusters by hand. If numbers are '
          'high, use an insecticide approved for cotton stainers, where '
          'registered.',
      safety: _spraySafety,
    ),

    // ----------------------------------------------------------------- Tomato
    KnowledgeCard(
      id: 'tomato_late_blight',
      crop: 'Tomato',
      title: 'Late blight',
      kind: CardKind.disease,
      symptoms:
          'Large, greasy, grey-green to dark brown blotches on leaves and '
          'stems, often with a pale edge. White mould forms on the underside '
          'of leaves in humid weather. Fruits show firm, brown, greasy patches. '
          'Whole plants can collapse in days. Caused by Phytophthora '
          'infestans. Thrives in cool, wet, misty weather.',
      management:
          'Remove and destroy infected plants at once. Do not plant near '
          'potatoes. Stake plants, prune lower leaves and space widely for '
          'airflow. Water the soil, not the leaves. In wet spells, spray a '
          'protectant fungicide such as a mancozeb or copper product before '
          'symptoms. Use a registered systemic product when blight is active.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'tomato_early_blight',
      crop: 'Tomato',
      title: 'Early blight',
      kind: CardKind.disease,
      symptoms:
          'Brown spots with rings like a target ("target spots") on older, '
          'lower leaves first, with yellowing around the spots. Leaves dry and '
          'drop, exposing fruit to sun. Dark sunken spots with rings may form '
          'on stems and at the fruit stalk end. Caused by an Alternaria '
          'fungus. Common in warm, wet weather and on weak plants.',
      management:
          'Rotate tomato away from potato, pepper and eggplant. Stake plants '
          'and remove lower spotted leaves. Mulch to stop soil splash. Water at '
          'the base. Feed plants well. If the disease spreads, spray a '
          'protectant fungicide such as a mancozeb or chlorothalonil product, '
          'where registered.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'tomato_tuta_absoluta',
      crop: 'Tomato',
      title: 'Tomato leafminer (Tuta absoluta)',
      kind: CardKind.pest,
      symptoms:
          'Leaves have pale, papery, blotch-shaped mines with small green '
          'caterpillars and dark droppings inside. Mined leaves dry up. Fruits '
          'have small holes, often under the green cap, and rot. Stems and '
          'growing tips may be bored. The crop can be destroyed. Also attacks '
          'potato and eggplant.',
      management:
          'Use insect-proof netting in nurseries. Use pheromone traps to watch '
          'and catch moths. Remove and destroy mined leaves and bored fruit in '
          'sealed bags. Destroy crop residue after harvest. Rotate away from '
          'tomato, potato and eggplant. Use Bt or neem products. If needed, use '
          'an approved spinetoram, emamectin benzoate or chlorantraniliprole '
          'product where registered, rotating groups.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'tomato_bacterial_wilt',
      crop: 'Tomato',
      title: 'Bacterial wilt',
      kind: CardKind.disease,
      symptoms:
          'The whole plant wilts suddenly while leaves are still green, first '
          'in the heat of the day, then stays wilted. The stem inside is brown. '
          'Put a cut stem in clear water: milky white threads stream out. '
          'Caused by Ralstonia bacteria in soil and water. Worse in hot, wet '
          'conditions. Also attacks pepper, eggplant and potato.',
      management:
          'Rotate for several seasons with cereals, beans or cabbage; avoid '
          'tomato, pepper, eggplant and potato. Plant resistant varieties or '
          'graft onto resistant rootstocks. Pull out wilted plants with their '
          'roots and destroy them. Do not irrigate from infected fields. Clean '
          'tools. Raise beds for drainage.',
    ),
    KnowledgeCard(
      id: 'tomato_yellow_leaf_curl',
      crop: 'Tomato',
      title: 'Tomato yellow leaf curl',
      kind: CardKind.disease,
      symptoms:
          'Young leaves are small, curled upward and cupped, with yellow edges. '
          'Plants are stunted and bushy, with short stems. Flowers drop and few '
          'fruits form. Plants infected young give almost no yield. Caused by '
          'viruses spread by whiteflies. Worse in hot, dry seasons when '
          'whiteflies are many.',
      management:
          'Plant tolerant varieties. Raise seedlings under insect-proof net. '
          'Pull out and destroy infected plants early. Remove weeds that host '
          'whiteflies. Use yellow sticky traps. Do not plant new tomato next to '
          'old infected fields. Leave a tomato-free break between seasons.',
    ),
    KnowledgeCard(
      id: 'tomato_fusarium_wilt',
      crop: 'Tomato',
      title: 'Fusarium wilt',
      kind: CardKind.disease,
      symptoms:
          'Lower leaves turn yellow, often on one side of the plant or one side '
          'of a leaf. Leaves wilt in the heat of the day and later die. Cutting '
          'the stem near the base shows brown streaks inside. Plants wilt '
          'slowly, unlike the sudden green wilt of bacterial wilt. Caused by a '
          'soil fungus. Worse in warm, sandy, acid soils.',
      management:
          'Plant resistant varieties. Rotate away from tomato for several '
          'seasons. Use clean seedlings from clean soil. Graft onto resistant '
          'rootstocks where available. Pull out and destroy wilted plants. Lime '
          'acid soils where advised. '
          'Avoid wounding roots when weeding. Keep plants well fed with '
          'balanced fertiliser.',
    ),
    KnowledgeCard(
      id: 'tomato_blossom_end_rot',
      crop: 'Tomato',
      title: 'Blossom end rot',
      kind: CardKind.disorder,
      symptoms:
          'A dark brown to black, sunken, leathery patch at the bottom end of '
          'the fruit, opposite the stalk. It starts as a small water-soaked '
          'spot. Leaves look healthy. Not a disease: caused by lack of calcium '
          'in the fruit, mostly from uneven watering. Also seen in pepper and '
          'watermelon.',
      management:
          'Water regularly and evenly; do not let soil dry out and then flood. '
          'Mulch to keep soil moisture steady. Avoid too much nitrogen. Lime '
          'acid soils before planting where advised. Remove affected fruit. '
          'Later fruits are often normal once watering is steady.',
    ),

    // ----------------------------------------------------------------- Pepper
    KnowledgeCard(
      id: 'pepper_bacterial_leaf_spot',
      crop: 'Pepper',
      title: 'Bacterial leaf spot',
      kind: CardKind.disease,
      symptoms: 'Small, water-soaked spots on leaves become brown, angular and '
          'scabby, often with a yellow edge. Many spots make leaves yellow and '
          'drop. Fruits show raised, rough, brown scabs. Caused by Xanthomonas '
          'bacteria, spread by rain splash, handling and infected seed. Worse '
          'in warm, wet weather.',
      management:
          'Use clean, certified seed and healthy seedlings. Rotate away from '
          'pepper and tomato. Avoid working with plants when wet. Water at the '
          'base. Remove and destroy crop debris. Where approved, spray a '
          'copper-based product to slow spread in wet weather.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'pepper_anthracnose',
      crop: 'Pepper',
      title: 'Pepper anthracnose (fruit rot)',
      kind: CardKind.disease,
      symptoms:
          'Round, sunken, water-soaked spots on ripening fruit. Spots grow and '
          'show rings of orange or pink spore masses, later dark dots. Fruits '
          'rot and shrivel. Leaves usually look healthy. Caused by '
          'Colletotrichum fungi carried in seed and debris. Worse in warm, wet '
          'weather.',
      management:
          'Use clean seed. Rotate away from pepper and tomato. Remove and '
          'destroy rotten fruit. Harvest ripe fruit promptly. Space plants for '
          'airflow and avoid overhead watering. In wet weather, a registered '
          'protectant fungicide such as a mancozeb or copper product can '
          'protect fruit.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'pepper_viruses',
      crop: 'Pepper',
      title: 'Pepper mosaic and mottle viruses',
      kind: CardKind.disease,
      symptoms:
          'Leaves show light and dark green mosaic, mottling or dark green '
          'bands along the veins. Leaves may be narrow, wrinkled and curled. '
          'Plants are stunted. Fruits are small, deformed and mottled. Several '
          'viruses, mostly spread by aphids, some by whiteflies or touch.',
      management:
          'Use healthy seedlings. Pull out and destroy plants with symptoms '
          'early. Control weeds around the field. Plant a border of maize or '
          'another tall crop to reduce aphid entry. Wash hands and tools after '
          'handling sick plants. Plant tolerant varieties.',
    ),
    KnowledgeCard(
      id: 'pepper_sunscald',
      crop: 'Pepper',
      title: 'Sunscald',
      kind: CardKind.disorder,
      symptoms:
          'A pale, whitish or yellow, soft patch on the side of the fruit '
          'facing the sun. The patch becomes thin, dry and papery, and may grow '
          'black or grey mould later. Fruits on plants that lost leaves are '
          'worst. Not a disease: caused by strong direct sun. Also seen on '
          'tomato.',
      management:
          'Keep plants leafy: control leaf diseases and do not over-prune. '
          'Plant at a spacing that lets leaves shade the fruit. Use light shade '
          'nets in very hot areas. Water well during heat. Harvest ripe fruit '
          'on time. '
          'Remove scalded fruit, as they can rot.',
    ),

    // ------------------------------------------------------------------- Okra
    KnowledgeCard(
      id: 'okra_flea_beetle',
      crop: 'Okra',
      title: 'Flea beetles on okra',
      kind: CardKind.pest,
      symptoms:
          'Many small round holes in leaves, like shot holes. Young leaves '
          'look like a sieve. Seedlings may die. Small, shiny, metallic blue, '
          'green or brown beetles jump away when touched. Worst on young '
          'plants. '
          'Leaves may turn brown and dry around the holes.',
      management:
          'Plant early and use healthy, vigorous seedlings. Remove weeds and '
          'crop residues. Spray neem seed extract on young plants. If seedlings '
          'are being destroyed, use an insecticide approved for okra, where '
          'registered. '
          'Sow a little extra seed to allow for seedling loss. Rotate away '
          'from okra and cotton.',
      safety: _spraySafety,
    ),

    // ------------------------------------------------------------------ Onion
    KnowledgeCard(
      id: 'onion_purple_blotch',
      crop: 'Onion',
      title: 'Purple blotch',
      kind: CardKind.disease,
      symptoms:
          'Small white, sunken spots on leaves grow into large oval purple '
          'patches with yellow edges, often with rings. Leaves bend and '
          'collapse at the spot. Dark velvety mould forms in humid weather. '
          'Bulbs may rot at the neck. Caused by an Alternaria fungus. Worse in '
          'warm, humid weather and after thrips damage.',
      management:
          'Rotate away from onion and garlic. Space plants widely and avoid '
          'overhead watering late in the day. Control thrips. Remove crop '
          'debris. Use balanced fertiliser. If spots spread, use a registered '
          'protectant fungicide such as a mancozeb product. '
          'Store only well-dried bulbs.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'onion_thrips',
      crop: 'Onion',
      title: 'Onion thrips',
      kind: CardKind.pest,
      symptoms:
          'Silvery-white streaks and patches on leaves, with tiny black dots '
          'of droppings. Leaf tips turn brown and dry. Leaves may twist and '
          'bend. Bulbs are small. Tiny, slender, pale yellow insects hide in '
          'the leaf folds at the neck. Worse in hot, dry weather.',
      management:
          'Remove crop debris and weeds. Do not plant next to old onion '
          'fields. Overhead watering or rain knocks thrips off. Use blue sticky '
          'traps to check numbers. Spray neem products. If damage spreads, use '
          'an insecticide approved for onion thrips, where registered, and '
          'rotate groups.',
      safety: _spraySafety,
    ),

    // --------------------------------------------------------------- Cabbage
    KnowledgeCard(
      id: 'cabbage_diamondback_moth',
      crop: 'Cabbage',
      title: 'Diamondback moth',
      kind: CardKind.pest,
      symptoms:
          'Leaves have small holes and papery "windows" where only the thin '
          'skin is left. Small, pale green caterpillars wriggle fast and drop '
          'on a silk thread when touched. Heavy attack leaves skeletonised '
          'leaves and damaged heads. Also attacks kale and other cabbage-family '
          'crops. Worse in the dry season.',
      management:
          'Use clean seedlings. Use insect-proof net in nurseries. Intercrop '
          'with onion, garlic or tomato. Protect natural enemies, especially '
          'small parasitic wasps. Spray Bt or neem products. If needed, use an '
          'approved spinosad or emamectin benzoate product, where registered. '
          'Rotate groups, as this pest quickly resists insecticides.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'cabbage_black_rot',
      crop: 'Cabbage',
      title: 'Black rot',
      kind: CardKind.disease,
      symptoms:
          'Yellow, V-shaped patches start at the leaf edge and point toward '
          'the midrib. Veins in the patch turn black. Leaves dry and drop. Cut '
          'stems show a black ring. Heads are small and may rot. Caused by '
          'Xanthomonas bacteria carried in seed. Worse in warm, wet weather.',
      management:
          'Use certified or hot-water-treated seed. Rotate away from cabbage, '
          'kale and other cabbage-family crops for several seasons. Remove '
          'cabbage-family weeds. Do not work in wet crops. Remove and destroy '
          'infected plants and residue. '
          'Use clean seedlings from healthy nurseries. Avoid overhead '
          'watering.',
    ),

    // -------------------------------------------------------------- Cucurbits
    KnowledgeCard(
      id: 'cucurbit_downy_mildew',
      crop: 'Cucurbits',
      title: 'Downy mildew',
      kind: CardKind.disease,
      symptoms:
          'Angular yellow patches on the upper side of leaves, limited by the '
          'veins. Grey to purple fuzzy growth forms under the patches in humid '
          'mornings. Patches turn brown and leaves die. Affects cucumber, '
          'melon, watermelon, pumpkin and squash. Favoured by humid, wet '
          'weather.',
      management:
          'Plant tolerant varieties. Space plants for airflow. Water at the '
          'base in the morning. Remove infected leaves and old crops. In wet '
          'weather, use a registered protectant fungicide such as a mancozeb '
          'or copper product, and a systemic product if the disease is '
          'spreading.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'cucurbit_powdery_mildew',
      crop: 'Cucurbits',
      title: 'Powdery mildew',
      kind: CardKind.disease,
      symptoms:
          'White, powdery spots on both sides of leaves and on stems, as if '
          'dusted with flour. Spots spread to cover leaves, which turn yellow '
          'and dry. Older leaves are hit first. Fruits are small and sunburnt. '
          'Common in dry weather with humid nights.',
      management:
          'Plant tolerant varieties. Space plants for airflow and light. Remove '
          'badly infected leaves. Avoid too much nitrogen. If needed, use a '
          'registered sulphur or other approved fungicide. Some melons are '
          'sensitive to sulphur; check the label. '
          'Remove old crops after harvest.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'cucurbit_fruit_fly',
      crop: 'Cucurbits',
      title: 'Melon fruit fly',
      kind: CardKind.pest,
      symptoms:
          'Young fruits have small puncture marks, sometimes with oozing sap. '
          'Fruits become soft, rot and drop. Inside are many white maggots. '
          'Fruits may be deformed. Adults are brown-yellow flies with clear '
          'wings marked with dark bands. Attacks pumpkin, cucumber, melon and '
          'watermelon.',
      management:
          'Collect fallen and rotten fruits every few days and destroy them: '
          'bury them deep or seal them in bags in the sun. Cover young fruits '
          'with paper or cloth bags. Use fruit fly traps with lures. Where '
          'registered, apply a protein bait with an approved insecticide as '
          'spot sprays, not cover sprays.',
      safety: _spraySafety,
    ),

    // ----------------------------------------------------------------- Citrus
    KnowledgeCard(
      id: 'citrus_greening',
      crop: 'Citrus',
      title: 'Citrus greening (HLB)',
      kind: CardKind.disease,
      symptoms:
          'Leaves show blotchy, uneven yellow mottling that is different on '
          'each side of the midrib. Leaves are small and upright. Branches die '
          'back. Fruits are small, lopsided, bitter and stay green at the '
          'bottom end. Seeds are aborted. Caused by bacteria spread by psyllid '
          'insects and infected budwood.',
      management:
          'There is no cure. Buy certified, disease-free seedlings from '
          'approved nurseries. Remove and destroy infected trees. Control '
          'psyllids with advice from your extension officer. Inspect new '
          'flush for psyllids and remove weed host plants. Report suspected '
          'trees, especially in new areas.',
    ),
    KnowledgeCard(
      id: 'citrus_gummosis',
      crop: 'Citrus',
      title: 'Phytophthora gummosis and foot rot',
      kind: CardKind.disease,
      symptoms:
          'Amber gum oozes from cracks in the bark at the base of the trunk. '
          'The bark under it is brown, wet and dead. Leaves turn yellow along '
          'the veins and drop. The tree declines and fruit is small. Fruit near '
          'the ground may get brown rot. Caused by Phytophthora fungi in wet '
          'soil.',
      management:
          'Plant on resistant rootstocks with the graft union well above the '
          'soil. Keep soil, mulch and weeds away from the trunk. Improve '
          'drainage and do not let water stand near the trunk. Scrape off dead '
          'bark and paint the area with a registered copper-based paste. Prune '
          'low branches.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'citrus_fruit_leaf_spot',
      crop: 'Citrus',
      title: 'Pseudocercospora fruit and leaf spot',
      kind: CardKind.disease,
      symptoms:
          'Round leaf spots with light brown or grey centres and a bright '
          'yellow halo. Leaves drop. Fruits show round, dark, slightly sunken '
          'spots with yellow halos, then rot and drop early. Caused by a fungus. '
          'Common in humid parts of East and Central Africa.',
      management:
          'Remove and destroy fallen leaves and fruits. Prune to open the '
          'canopy. Remove infected branches. Feed trees well. Where the disease '
          'is common, spray a copper-based fungicide during rainy seasons, '
          'where registered. '
          'Plant clean seedlings from approved nurseries. Control weeds under '
          'trees.',
      safety: _spraySafety,
    ),

    // ------------------------------------------------------------------ Mango
    KnowledgeCard(
      id: 'mango_anthracnose',
      crop: 'Mango',
      title: 'Mango anthracnose',
      kind: CardKind.disease,
      symptoms:
          'Black spots on young leaves, flowers and small fruit. Flowers turn '
          'black and drop, so few fruits set. On ripening fruit, round black '
          'sunken spots grow and join, and the flesh rots. Spots often run in '
          'streaks down the fruit. Caused by a Colletotrichum fungus. Worse in '
          'wet weather during flowering.',
      management:
          'Prune to open the canopy. Remove dead twigs, dried flowers and '
          'mummified fruit. Collect fallen fruit and leaves. Harvest carefully '
          'and avoid bruising. Where registered, spray a copper fungicide or '
          'other approved product during flowering and fruit set in wet '
          'weather.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'mango_fruit_fly',
      crop: 'Mango',
      title: 'Mango fruit flies',
      kind: CardKind.pest,
      symptoms:
          'Small sting marks on the fruit skin, sometimes with dark patches '
          'around them. Fruits rot from inside and drop early. Cut fruit shows '
          'white maggots. Adults are small yellow-brown flies with patterned '
          'wings. Also attack citrus, guava, papaya and other fruits.',
      management:
          'Collect fallen and rotten fruit every few days and destroy it: bury '
          'deep or seal in bags. Harvest at mature-green stage. Use male lure '
          'traps. Protect weaver ants, which hunt flies. Where registered, '
          'apply a protein bait mixed with an approved insecticide as spot '
          'sprays on a few branches. Coordinate with neighbours.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'mango_powdery_mildew',
      crop: 'Mango',
      title: 'Mango powdery mildew',
      kind: CardKind.disease,
      symptoms:
          'White, powdery growth on flowers, flower stalks, young leaves and '
          'tiny fruit. Flowers turn brown and drop. Young fruit fall. Leaves '
          'may curl and show purple-brown blotches. Common during flowering in '
          'cool, dry nights with humid mornings. '
          'Caused by a fungus.',
      management:
          'Prune to let in light and air. Remove infected flower stalks and '
          'fallen debris. Where registered, spray a sulphur-based or other '
          'approved fungicide at flowering, following extension advice. '
          'Keep trees healthy with manure and water. Clear weeds under trees. '
          'Work with neighbours, as spores spread by wind.',
      safety: _spraySafety,
    ),

    // ----------------------------------------------------------------- Cashew
    KnowledgeCard(
      id: 'cashew_powdery_mildew',
      crop: 'Cashew',
      title: 'Cashew powdery mildew',
      kind: CardKind.disease,
      symptoms:
          'White to grey powdery growth on young leaves, flowers, and young '
          'nuts and apples. Flowers turn black and dry. Young nuts are '
          'deformed, shrivelled and drop. Leaves curl and may drop. Causes '
          'large yield losses in East and Southern Africa during flowering.',
      management:
          'Plant tolerant clones. Prune trees and remove dead branches for '
          'airflow. Remove weeds and debris under trees. Where registered, dust '
          'or spray sulphur or another approved fungicide at flushing and '
          'flowering, following extension advice. '
          'Replace very old, low-yielding trees with tolerant clones over '
          'time.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'cashew_sucking_bugs',
      crop: 'Cashew',
      title: 'Cashew sucking bugs',
      kind: CardKind.pest,
      symptoms:
          'Dark brown to black sunken spots on young shoots, flower stalks, '
          'nuts and apples, where bugs fed. Shoots wilt and die back. Flowers '
          'dry up. Young nuts shrivel, become deformed and drop. The bugs are '
          'slender, brown or reddish, and hide during the day.',
      management:
          'Protect and encourage weaver ants (red ants) in the trees; they '
          'control these bugs well. Connect trees with strings so ants can '
          'move between them. Prune dead shoots. Remove weed host plants. Ask '
          'your extension officer before using any insecticide.',
    ),

    // --------------------------------------------------------------- Oil palm
    KnowledgeCard(
      id: 'oil_palm_vascular_wilt',
      crop: 'Oil palm',
      title: 'Fusarium vascular wilt',
      kind: CardKind.disease,
      symptoms:
          'Older fronds turn yellow and dry, then break and hang down around '
          'the trunk. New spear leaves are short, pale and few. Some palms dry '
          'out and die quickly. Cutting the frond base or trunk shows brown '
          'streaks inside. Caused by a soil Fusarium fungus. Found in West and '
          'Central Africa.',
      management:
          'Plant wilt-tolerant planting material from approved seed gardens. '
          'Cut down and remove dead and dying palms. Do not replant susceptible '
          'material in affected sites. Keep palms well fed, especially with '
          'potassium. Ask your extension officer or research station for '
          'advice.',
    ),

    // ------------------------------------------------- Pests of many crops
    KnowledgeCard(
      id: 'african_bollworm',
      crop: 'Many crops',
      title: 'African bollworm (Helicoverpa)',
      kind: CardKind.pest,
      symptoms:
          'Round holes bored into tomato fruits, cotton bolls, pods, maize '
          'cobs and pepper. Damaged fruits rot and drop. Caterpillars are '
          'green, brown or pink with pale stripes along the sides and feed with '
          'half the body inside the fruit. Young larvae also eat leaves and '
          'flowers.',
      management:
          'Scout often and hand-pick caterpillars. Remove and destroy bored '
          'fruits. Plough after harvest to kill pupae. Protect natural enemies. '
          'Use Bt, neem or virus biopesticides on young larvae. If needed, use '
          'an insecticide approved for bollworm on that crop, where registered, '
          'and rotate groups to avoid resistance.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'aphids',
      crop: 'Many crops',
      title: 'Aphids',
      kind: CardKind.pest,
      symptoms:
          'Clusters of small, soft, green, black, yellow or grey insects on '
          'young shoots, flower buds and under leaves. Leaves curl, pucker and '
          'turn yellow. Leaves are sticky with honeydew and may turn black with '
          'sooty mould. Ants often run among them. Aphids spread many virus '
          'diseases. Worse in dry weather.',
      management:
          'Check plants often. Protect ladybirds, lacewings, hoverflies and '
          'parasitic wasps, which eat aphids; avoid needless broad-spectrum '
          'sprays. Spray plants with water or a mild soap solution. Use neem '
          'products. Remove badly infested shoots. Avoid too much nitrogen. If '
          'aphids spread fast, use an insecticide approved for that crop, where '
          'registered.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'whiteflies',
      crop: 'Many crops',
      title: 'Whiteflies',
      kind: CardKind.pest,
      symptoms:
          'Tiny white, winged insects fly up in a cloud when leaves are shaken. '
          'Pale, flat, scale-like young stages sit on the underside of leaves. '
          'Leaves turn yellow, become sticky and black with sooty mould. '
          'Whiteflies spread viruses of cassava, tomato, pepper, beans and '
          'sweet potato. Worse in hot, dry weather.',
      management:
          'Remove weeds and old crop residues that host whiteflies. Use '
          'insect-proof net in nurseries. Use yellow sticky traps. Spray neem '
          'or soap solution under leaves. Protect natural enemies. Plant '
          'virus-tolerant varieties. If needed, use an insecticide approved for '
          'whiteflies on that crop, where registered, and rotate groups.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'locusts',
      crop: 'Many crops',
      title: 'Locusts and grasshopper swarms',
      kind: CardKind.pest,
      symptoms:
          'Large swarms of flying locusts, or bands of wingless hoppers walking '
          'together, arrive suddenly. Leaves are eaten to the midrib or '
          'stripped completely. Cereals, pasture and trees may be left bare. '
          'Desert locust adults are pink when young and yellow when mature. '
          'Outbreaks follow good rains in desert areas.',
      management:
          'Report swarms and hopper bands at once to your extension officer or '
          'plant protection service. Control is done by trained teams using '
          'approved insecticides or fungal biopesticides. Do not spray yourself '
          'without training. Hopper bands can be driven into trenches and '
          'buried. Protect seedlings and small fields by scaring swarms with '
          'noise.',
      safety:
          'After control teams spray, keep people and animals out of treated '
          'fields and pasture for the period they advise. Do not eat locusts '
          'from sprayed areas. Wash crops before eating. Report any illness '
          'after spraying to a health worker.',
    ),
    KnowledgeCard(
      id: 'termites',
      crop: 'Many crops',
      title: 'Termites',
      kind: CardKind.pest,
      symptoms:
          'Plants wilt, turn yellow and die suddenly, often in patches. Roots '
          'and stem bases are hollowed out and filled with soil. Mud tubes or '
          'soil sheets cover stems and tree trunks. Maize falls over late in '
          'the season. Small, pale, soft-bodied insects are found in the soil. '
          'Worse in dry spells and on stressed plants.',
      management:
          'Keep plants vigorous with manure and water. Avoid wounding roots '
          'and stems. Remove old stumps and dead wood near fields. Harvest on '
          'time; do not leave maize standing late. Destroy nearby mounds and '
          'the queen where possible. If losses are severe, use a soil or seed '
          'treatment approved for termites, where registered.',
      safety: _seedTreatmentSafety,
    ),
    KnowledgeCard(
      id: 'red_spider_mite',
      crop: 'Many crops',
      title: 'Red spider mites',
      kind: CardKind.pest,
      symptoms:
          'Leaves show many tiny pale or yellow speckles, then turn bronze, '
          'dry and fall. Fine silk webbing covers the underside of leaves and '
          'shoot tips. Tiny red, orange or green mites move on the webbing. '
          'Common on tomato, beans, eggplant, cotton and roses. Worse in hot, '
          'dry, dusty weather.',
      management:
          'Spray the underside of leaves with water. Remove and destroy badly '
          'infested leaves. Water plants well in dry spells. Avoid '
          'broad-spectrum insecticides that kill predatory mites. Use neem or '
          'soap sprays. If needed, use an acaricide (miticide) approved for '
          'that crop, where registered, and rotate groups.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'root_knot_nematodes',
      crop: 'Many crops',
      title: 'Root-knot nematodes',
      kind: CardKind.pest,
      symptoms:
          'Plants are stunted and yellow, and wilt in the heat of the day '
          'even with moist soil. Roots have round or long swellings (galls). '
          'Galls are part of the root and cannot be rubbed off, unlike the '
          'nodules on bean roots. Caused by tiny soil worms. Common on tomato, '
          'pepper, okra, carrot and many other crops in sandy soils.',
      management:
          'Rotate with cereals, onion or other non-host crops. Use resistant '
          'varieties or rootstocks. Raise seedlings in clean soil. Add plenty '
          'of compost or manure. Plant marigold (Tagetes) as a rotation crop. '
          'Uproot and destroy infected roots after harvest. Leave land fallow '
          'or plough in the dry season to expose nematodes.',
    ),
    KnowledgeCard(
      id: 'striga',
      crop: 'Many crops',
      title: 'Striga (witchweed)',
      kind: CardKind.pest,
      symptoms:
          'A parasitic weed with bright purple, pink, red or white flowers '
          'grows attached to the roots of maize, sorghum, millet, rice or '
          'cowpea. Before the weed appears, the crop is stunted, yellow and '
          'wilts as if in drought. Leaf tips and edges may scorch. Yield losses '
          'are severe. Worse in poor, sandy soils.',
      management:
          'Pull out Striga before it flowers and burn it. Rotate cereals with '
          'cowpea, groundnut or soybean. Use push-pull with Desmodium. Plant '
          'Striga-resistant varieties. Add manure and fertiliser to improve '
          'soil. Where available, plant herbicide-coated, Striga-resistant '
          'maize seed, following the instructions on the pack.',
      safety: 'Handle herbicide-coated seed with gloves and wash hands after. '
          'Never eat coated seed or feed it to animals. Keep it away from '
          'children. Follow the pack instructions on spacing and intercropping '
          'with other crops.',
    ),
    KnowledgeCard(
      id: 'african_armyworm',
      crop: 'Many crops',
      title: 'African armyworm',
      kind: CardKind.pest,
      symptoms:
          'Large numbers of caterpillars appear suddenly after the first rains '
          'and march across fields. Grasses, maize, sorghum, millet, rice and '
          'pasture are eaten to the ground. Caterpillars are velvety black with '
          'thin pale lines along the sides and a green-yellow belly. Common in '
          'East and Southern Africa.',
      management:
          'Check fields and pasture daily after early rains. Report outbreaks '
          'to your extension officer at once; they track armyworm and can help. '
          'Treat young larvae early. Ask about virus biopesticides. If needed, '
          'use an insecticide approved for armyworm, where registered. Dig '
          'trenches to stop marching larvae in small plots.',
      safety: _spraySafety,
    ),
    KnowledgeCard(
      id: 'cutworms',
      crop: 'Many crops',
      title: 'Cutworms',
      kind: CardKind.pest,
      symptoms: 'Young seedlings are cut off at or just below the soil surface '
          'overnight and lie on the ground. Damage moves along rows. Fat, '
          'smooth, grey-brown caterpillars curl into a C shape when found in '
          'the soil near cut plants. Common on maize, tomato, cabbage, beans '
          'and tobacco.',
      management:
          'Plough and weed fields well before planting. Search the soil around '
          'cut plants in the early morning and kill the caterpillars. Place '
          'collars of paper, plastic or cardboard around transplanted stems. '
          'Replant gaps quickly. Keep the field free of weeds for two weeks '
          'before planting.',
    ),

    // ------------------------------------------------- Nutrient deficiencies
    KnowledgeCard(
      id: 'nitrogen_deficiency',
      crop: 'Many crops',
      title: 'Nitrogen deficiency',
      kind: CardKind.deficiency,
      symptoms:
          'Older, lower leaves turn pale green then yellow first; young leaves '
          'stay greener. The whole plant is small, thin and pale. In maize and '
          'sorghum, yellowing runs from the leaf tip down the midrib in a V '
          'shape. Lower leaves dry early. Common in sandy, worn-out soils and '
          'after heavy rain. Different from sulphur deficiency, which yellows '
          'young leaves first.',
      management:
          'Add compost or animal manure. Rotate or intercrop cereals with '
          'legumes such as beans, cowpea, groundnut or soybean. Return crop '
          'residues to the soil. Apply nitrogen fertiliser such as urea or CAN '
          'in split doses: some at planting, the rest as top dressing when '
          'plants are knee-high, on moist soil.',
    ),
    KnowledgeCard(
      id: 'phosphorus_deficiency',
      crop: 'Many crops',
      title: 'Phosphorus deficiency',
      kind: CardKind.deficiency,
      symptoms:
          'Plants are small and slow-growing, with dark green leaves. Older '
          'leaves and stems turn purple or reddish, often from the leaf edges. '
          'In maize, young plants show purple leaf edges. Roots are poor, and '
          'flowering and maturity are late. Common in acid, weathered soils and '
          'in cold, wet weather.',
      management:
          'Apply a phosphorus fertiliser such as DAP, TSP or NPK at planting, '
          'placed near but not touching the seed. Use local rock phosphate '
          'where available. Add manure or compost. Lime very acid soils where '
          'advised. Inoculate legumes to help them use phosphorus.',
    ),
    KnowledgeCard(
      id: 'potassium_deficiency',
      crop: 'Many crops',
      title: 'Potassium deficiency',
      kind: CardKind.deficiency,
      symptoms:
          'Edges and tips of older, lower leaves turn yellow, then brown and '
          'dry, looking scorched. The middle of the leaf stays green. Stems '
          'are weak and plants fall over. Fruits ripen unevenly and are small. '
          'In banana, older leaves yellow-orange and fold. Common in sandy '
          'soils and fields cropped for many years.',
      management:
          'Return crop residues, banana leaves and stems to the soil. Add '
          'manure, compost or wood ash. Apply a potassium fertiliser such as '
          'muriate of potash (MOP) or a compound NPK. Mulch to reduce '
          'leaching. '
          'Split potash doses on sandy soils where advised.',
    ),
    KnowledgeCard(
      id: 'magnesium_deficiency',
      crop: 'Many crops',
      title: 'Magnesium deficiency',
      kind: CardKind.deficiency,
      symptoms:
          'Older leaves turn yellow between the veins while the veins stay '
          'green, giving a striped or net pattern. Yellow areas may turn '
          'reddish-purple or brown. In maize, older leaves have yellow stripes '
          'along the veins. Common in acid, sandy soils and where high potassium '
          'fertiliser was used.',
      management:
          'Use dolomitic lime on acid soils where advised; it adds magnesium. '
          'Add manure or compost. Apply a fertiliser containing magnesium, such '
          'as magnesium sulphate, to the soil or as a foliar spray. Avoid '
          'excess potassium fertiliser. '
          'Keep soil pH right for the crop.',
    ),
    KnowledgeCard(
      id: 'zinc_deficiency',
      crop: 'Many crops',
      title: 'Zinc deficiency',
      kind: CardKind.deficiency,
      symptoms:
          'In maize, young leaves show broad white or pale yellow bands on '
          'both sides of the midrib, near the leaf base. Plants are short with '
          'short internodes. In rice, leaves show brown rusty spots and plants '
          'are stunted. In fruit trees, new leaves are small and narrow, '
          'crowded in rosettes ("little leaf"). Common in sandy, high-pH or '
          'flooded soils.',
      management:
          'Add manure or compost. Use a fertiliser blend that contains zinc, '
          'or zinc sulphate, at planting. For a quick fix, spray a zinc foliar '
          'fertiliser on young plants following the label. In rice, drain '
          'fields briefly where advised. '
          'Avoid over-liming and too much phosphorus fertiliser.',
    ),
    KnowledgeCard(
      id: 'iron_deficiency',
      crop: 'Many crops',
      title: 'Iron deficiency',
      kind: CardKind.deficiency,
      symptoms:
          'The youngest leaves at the top turn pale yellow between the veins, '
          'while the veins stay green. In severe cases new leaves turn almost '
          'white. Older leaves stay green. Common in high-pH, chalky or '
          'over-limed soils and in waterlogged soil. Different from magnesium '
          'deficiency, which affects older leaves first.',
      management:
          'Do not over-lime. Improve drainage. Add plenty of compost or '
          'manure. Use an iron foliar fertiliser such as an iron chelate on '
          'young leaves, following the label. Choose tolerant varieties on '
          'high-pH soils. '
          'On alkaline soils, use acid-forming fertilisers such as ammonium '
          'sulphate where advised.',
    ),
    KnowledgeCard(
      id: 'sulphur_deficiency',
      crop: 'Many crops',
      title: 'Sulphur deficiency',
      kind: CardKind.deficiency,
      symptoms:
          'The youngest leaves turn pale green to yellow all over, including '
          'the veins, while older leaves stay greener. Plants are small and '
          'thin. Legumes form few root nodules. Different from nitrogen '
          'deficiency, which yellows older leaves first. Common in sandy, '
          'low-organic soils and where only urea or DAP is used.',
      management:
          'Add manure or compost. Use fertilisers that contain sulphur, such '
          'as ammonium sulphate, single super phosphate (SSP), or an NPK blend '
          'with sulphur. Gypsum also supplies sulphur. '
          'Return crop residues to the soil. Legumes need sulphur to fix '
          'nitrogen well. Ask your extension officer about a soil test.',
    ),
    KnowledgeCard(
      id: 'boron_deficiency',
      crop: 'Many crops',
      title: 'Boron deficiency',
      kind: CardKind.deficiency,
      symptoms:
          'Growing tips die back. New leaves are thick, brittle, curled and '
          'deformed. Stems may crack. Cabbage and cauliflower stems are hollow '
          'and brown inside. Groundnut kernels have a hollow, dark centre. '
          'Flowers drop and fruit or seed set is poor; fruits may be cracked '
          'or corky. Common in sandy, leached soils and dry spells.',
      management:
          'Add compost or manure. Apply a boron fertiliser or a blend that '
          'contains boron, following the label and extension advice. Use only '
          'small amounts: too much boron poisons plants. Spread it evenly. '
          'Mulch and water in dry spells to help roots take up boron. Ask '
          'your extension officer for advice on your soil.',
    ),

    // ------------------------------------------------------------- Disorders
    KnowledgeCard(
      id: 'drought_stress',
      crop: 'Many crops',
      title: 'Drought stress',
      kind: CardKind.disorder,
      symptoms:
          'Leaves wilt, droop or roll in the heat of the day. Maize leaves roll '
          'into thin tubes and look grey-green. Leaf tips and edges turn brown '
          'and dry. Flowers and young fruit drop; maize silks appear late, '
          'giving gaps in the cob. Plants recover at night if stress is mild, '
          'unlike bacterial wilt.',
      management:
          'Mulch to keep soil moist. Water early morning or evening, at the '
          'base. Plant drought-tolerant and early-maturing varieties. Plant on '
          'time with the first rains. Weed early to cut competition. Use '
          'tied ridges, planting basins or zai pits to catch rain. Add organic '
          'matter to hold water.',
    ),
    KnowledgeCard(
      id: 'waterlogging',
      crop: 'Many crops',
      title: 'Waterlogging',
      kind: CardKind.disorder,
      symptoms: 'Plants turn yellow, starting with lower leaves, and wilt even '
          'though the soil is wet. Growth stops. Roots are brown or black, '
          'soft and smell sour. Plants in low spots or furrows are worst. '
          'Often follows heavy rain or over-watering on clay soil.',
      management:
          'Plant on ridges, mounds or raised beds. Dig drainage channels to '
          'carry water away. Avoid planting in low spots that flood. Do not '
          'over-water. Add organic matter to improve soil structure. Choose '
          'crops that tolerate wet soil, such as rice or cocoyam, for wet '
          'sites.',
    ),
    KnowledgeCard(
      id: 'herbicide_injury',
      crop: 'Many crops',
      title: 'Herbicide injury',
      kind: CardKind.disorder,
      symptoms:
          'Leaves are twisted, cupped, strap-like or fan-shaped, and stems '
          'bend or curl. Other types cause bleached white or yellow leaves, or '
          'burnt spots. Damage often follows a pattern: the spray path, field '
          'edge, or direction of wind. Several crop types nearby show it at '
          'once. Common after spraying weedkillers nearby or using a dirty '
          'sprayer.',
      management:
          'Read the label and use the right herbicide for the crop. Calibrate '
          'the sprayer. Do not spray in wind or heat. Keep a separate sprayer '
          'for herbicides, or wash it well after use. Keep water and care for '
          'damaged plants; mildly affected plants often recover. Remove badly '
          'damaged plants.',
      safety: 'Wear gloves, a mask, long sleeves and boots when mixing and '
          'spraying herbicide. Follow the label rate. Do not spray near water, '
          'homes or other crops. Keep children and animals away. Store '
          'products locked and in original containers.',
    ),
    KnowledgeCard(
      id: 'fertiliser_burn',
      crop: 'Many crops',
      title: 'Fertiliser burn',
      kind: CardKind.disorder,
      symptoms:
          'Leaf tips and edges turn brown and dry, looking scorched, soon after '
          'fertiliser is applied. Seedlings near fertiliser wilt or die. A '
          'white crust may form on the soil. Leaves splashed with fertiliser '
          'have small burnt spots. Worse in dry soil.',
      management:
          'Place fertiliser a hand-width from the plant stem, not on it. Apply '
          'on moist soil and cover it. Split nitrogen fertiliser into smaller '
          'doses. Do not apply on wet leaves. Water well after applying if '
          'possible. '
          'Use manure that is well rotted, not fresh.',
    ),
  ];
}
