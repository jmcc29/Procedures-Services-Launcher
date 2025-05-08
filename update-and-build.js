const { execSync } = require('child_process');
const fs = require('fs');
const readline = require('readline');

function run(command) {
  try {
    console.log(`\n> ${command}`);
    execSync(command, { stdio: 'inherit' });
  } catch (err) {
    console.error(`❌ Error al ejecutar: ${command}`);
    process.exit(1);
  }
}

// Detecta nombres de submódulos desde .gitmodules
function getSubmodules() {
  const gitmodules = fs.readFileSync('.gitmodules', 'utf-8');
  const matches = [...gitmodules.matchAll(/path = ([^\n]+)/g)];
  return matches.map(m => m[1]);
}

// Detecta contenedores activos del compose
function getRunningServices() {
  const result = execSync('docker compose ps --services --filter status=running').toString();
  return result.trim().split('\n').filter(Boolean);
}

// Pregunta al usuario si quiere actualizar solo uno
function askForSubmoduleChoice(submodules) {
  return new Promise((resolve) => {
    console.log('\nSubmódulos disponibles:');
    submodules.forEach((s, i) => console.log(`  ${i + 1}. ${s}`));
    console.log('  0. Todos');

    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });

    rl.question('\nSelecciona un submódulo a actualizar (por número): ', (answer) => {
      const index = parseInt(answer, 10);
      rl.close();
      if (isNaN(index) || index < 0 || index > submodules.length) {
        console.log('❌ Selección inválida.');
        process.exit(1);
      }
      if (index === 0) {
        resolve(submodules); // todos
      } else {
        resolve([submodules[index - 1]]);
      }
    });
  });
}

// Main
(async () => {
  const submodules = getSubmodules();
  const selectedSubmodules = await askForSubmoduleChoice(submodules);

  console.log('\n🔄 Actualizando submódulos...');
  for (const sub of selectedSubmodules) {
    //run(`git submodule update --init --recursive ${sub}`);
    run(`cd ${sub} && git checkout main && git pull origin main`);
  }

  const runningServices = getRunningServices();
  console.log('\n🧱 Ejecutando yarn build en contenedores activos...');
  for (const service of runningServices) {
    run(`docker compose exec ${service} yarn build`);
  }

  console.log('\n✅ Proceso completo.');
})();
