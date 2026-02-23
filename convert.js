async function main() {
  const [major] = process.versions.node.split(".").map(Number);

  if (major < 18) {
    console.error(
      `Unsupported Node.js ${process.versions.node}. sharp@0.34 requires Node.js 18+.`
    );
    console.error("Please upgrade Node.js or install an older sharp version.");
    process.exit(1);
  }

  const sharp = require("sharp");
  const [, , input, output] = process.argv;

  if (!input || !output) {
    console.log("Usage: node convert.js <input> <output>");
    process.exit(1);
  }

  try {
    await sharp(input).toFile(output);
    console.log(`Converted: ${input} -> ${output}`);
  } catch (error) {
    console.error("Conversion failed:", error.message);
    process.exit(1);
  }
}

main();
