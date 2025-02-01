importScripts('https://unpkg.com/sql.js@1.6.2/dist/sql-wasm.js');
importScripts('https://unpkg.com/sqflite_common_ffi_web@latest/dist/sqflite_sw.js');

let db;

self.onmessage = async function(e) {
  const data = e.data;
  try {
    switch (data.action) {
      case 'init':
        await initDb();
        self.postMessage({ id: data.id, result: 'ok' });
        break;
      default:
        self.postMessage({ id: data.id, error: 'Unknown action' });
    }
  } catch (e) {
    self.postMessage({ id: data.id, error: e.toString() });
  }
};

async function initDb() {
  if (!db) {
    const SQL = await initSqlJs({
      locateFile: file => `https://unpkg.com/sql.js@1.6.2/dist/${file}`
    });
    db = new SQL.Database();
  }
}
