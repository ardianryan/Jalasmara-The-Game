import {MongoClient} from 'mongodb';
const client=new MongoClient('mongodb://mongo:27018/?directConnection=true');
await client.connect();
try{await client.db('admin').command({replSetInitiate:{_id:'rs0',members:[{_id:0,host:'mongo:27018'}]}});}catch(e){if(e.codeName!=='AlreadyInitialized')throw e;}
for(let i=0;i<40;i++){const hello=await client.db('admin').command({hello:1});if(hello.isWritablePrimary){await client.close();process.exit(0);}await new Promise(r=>setTimeout(r,500));}
throw new Error('Replica set belum menjadi primary.');
