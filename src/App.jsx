import { useState } from 'react';
import Ludo from './Ludo';
import Domino from './Domino';

function App() {
  const [currentScreen, setCurrentScreen] = useState('menu');

  return (
    <div className="app-container">
      {currentScreen === 'menu' && (
        <div className="menu-screen">
          <h1>BOARD KINGS</h1>
          <p>ملوك الطاولة</p>
          
          <div className="menu-buttons">
            <button onClick={() => setCurrentScreen('ludo')}>Ludo - لودو</button>
            <button onClick={() => setCurrentScreen('domino')}>Domino - دومينو</button>
          </div>
        </div>
      )}

      {currentScreen === 'ludo' && (
        <Ludo onBack={() => setCurrentScreen('menu')} />
      )}

      {currentScreen === 'domino' && (
        <Domino onBack={() => setCurrentScreen('menu')} />
      )}
    </div>
  );
}

export default App;
