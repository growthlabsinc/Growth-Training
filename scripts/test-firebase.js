// Simple Firebase connection test
import { getFirestore, collection, addDoc } from 'firebase/firestore';
import { initializeApp } from 'firebase/app';

const firebaseConfig = {
  projectId: 'growth-70a85'
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function testConnection() {
  try {
    // Try to add a test document
    const testDoc = await addDoc(collection(db, 'test'), {
      message: 'Hello Firebase!',
      timestamp: new Date()
    });
    console.log('Firebase connection successful! Document written with ID: ', testDoc.id);
  } catch (error) {
    console.error('Firebase connection failed: ', error);
  }
}

testConnection();