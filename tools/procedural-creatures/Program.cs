using System.Security.Cryptography;
using System.Text.Json;
using PixelCreatures.Core;
using PixelCreatures.Core.Export;
using PixelCreatures.Core.Genetics;
using PixelCreatures.Core.Serialization;

const string revision = "a2207c4bd6f1be51d426684cf58f11668def7579";
string output = Path.GetFullPath(args.Length > 0 ? args[0] : "client-godot/resources/art/procedural");
Directory.CreateDirectory(output);
var registry = CreatureRegistry.CreateDefault();
var factory = new CreatureFactory(registry);
var serializer = new GenomeSerializer(registry);
var species = new[] {
    new Species("reef_seruni", "Ikan Seruni", "aquatic", "reef", 1518, 190, "sea"),
    new Species("pari_lamun", "Pari Lamun", "aquatic", "ray", 2903, 82, "sea"),
    new Species("sidat_smara", "Sidat Smara", "aquatic", "eel", 3711, 170, "sea"),
    new Species("ubur_smaragd", "Ubur Smara", "amorphous", "jelly", 4297, 180, "sea"),
    new Species("sotong_karang", "Gurita Karang", "amorphous", "octopus", 5113, 60, "sea"),
    new Species("ular_muara", "Ular Muara", "serpent", "snake", 6121, 108, "forest"),
    new Species("kepiting_bandar", "Kepiting Bandar", "arthropod", "crab", 7159, 65, "sea"),
    new Species("buntal_pasir", "Buntal Pasir", "aquatic", "puffer", 8231, 88, "sea"),
    new Species("hiu_segaran", "Hiu Segaran", "aquatic", "shark", 9391, 200, "sea"),
    new Species("kura_pesisir", "Kura-kura Pesisir", "reptile", "tortoise", 10459, 110, "forest")
};
var entries = new List<object>();
foreach (var item in species) {
    var family = registry.GetFamily(item.Family);
    var genome = GenomeFactory.Sample(family, item.Seed);
    var values = genome.CopyValues();
    family.SampleAnatomy(values, Rng.Derive(item.Seed, "jalasmara.anatomy"), item.Archetype);
    family.AdjustSample(values, Rng.Derive(item.Seed, "jalasmara.adjust"), item.Archetype);
    genome = genome.WithValues(values).WithName(item.Label)
        .With("color.hue", item.Hue).With("color.saturation", 0.46)
        .With("color.value", 0.62).With("color.bellyLight", 0.68)
        .With("color.markingDark", 0.40).With("color.outline", 0.50)
        .With("color.glow", 0.08).With("size", 0.34)
        .WithChoice("color.scheme", "analogous");
    var model = factory.Build(genome);
    var options = new SpritesheetOptions {
        Clips = new() { ClipKind.Idle, ClipKind.Walk },
        Directions = item.Habitat == "forest" ? new() { 0, 2, 4, 6 } : new() { 0, 4 },
        Fps = 12, Padding = 2, Quality = 1, DrawShadow = false, MaxPageSize = 8192
    };
    Console.WriteLine($"Generating {item.Id} from {item.Family}/{item.Archetype}, seed {item.Seed}...");
    var sheet = SpritesheetExporter.Export(model, registry, options, item.Id);
    var pages = new List<object>();
    for (int i = 0; i < sheet.Pages.Count; i++) {
        string file = sheet.Pages.Count == 1 ? item.Id + ".png" : $"{item.Id}_{i}.png";
        var page = sheet.Pages[i];
        byte[] png = PngEncoder.Encode(page.rgba, page.width, page.height);
        File.WriteAllBytes(Path.Combine(output, file), png);
        pages.Add(new { file, width = page.width, height = page.height, sha256 = Convert.ToHexString(SHA256.HashData(png)).ToLowerInvariant() });
    }
    File.WriteAllText(Path.Combine(output, item.Id + ".json"), sheet.MetadataJson + "\n");
    File.WriteAllText(Path.Combine(output, item.Id + ".genome.json"), serializer.Serialize(genome, new PresetMeta { CreatedWith = "Jalasmara offline adapter / Procedural Pixel Creatures", Notes = "Fictional coastal fauna; no AI source sprite or sacred cultural symbol.", Tags = new() { "jalasmara", item.Habitat, "procedural" } }) + "\n");
    entries.Add(new { id = item.Id, label = item.Label, family = item.Family, archetype = item.Archetype, seed = item.Seed, habitat = item.Habitat, metadata = item.Id + ".json", genome = item.Id + ".genome.json", frameWidth = sheet.FrameWidth, frameHeight = sheet.FrameHeight, frames = sheet.TotalFrames, pages });
    Console.WriteLine($"Exported {item.Id}: {sheet.TotalFrames} frames, {sheet.FrameWidth}x{sheet.FrameHeight} pixels each.");
}
File.WriteAllText(Path.Combine(output, "manifest.json"), JsonSerializer.Serialize(new { format = "jalasmara.procedural-creatures", formatVersion = 1, upstream = "https://github.com/idlerunner00/procedural-pixel-creatures", revision, license = "MIT", generatorVersion = CreatureFramework.GeneratorVersion, fps = 12, species = entries }, new JsonSerializerOptions { WriteIndented = true }) + "\n");
record Species(string Id, string Label, string Family, string Archetype, ulong Seed, double Hue, string Habitat);
