import React, { useState } from 'react';

function Ludo({ onBack }) {
  const [dice, setDice] = useState(1);

  const rollDice = () => {
    const newDice = Math.floor(Math.random() * 6) + 1;
    setDice(newDice);
  };

  return (
    <div className="ludo-container">
      <div className="ludo-header">
        <button className="back-btn" onClick={onBack}>رجوع</button>
        <h2>لعبة Ludo</h2>
      </div>
      
      <div className="ludo-board-wrapper">
        <svg viewBox="0 0 15 15" className="ludo-svg">
          {/* الخلفية */}
          <rect width="15" height="15" fill="#fff" stroke="#333" strokeWidth="0.1" />
          
          {/* البيوت الأربعة والقطع */}
          {/* الأحمر */}
          <rect x="0" y="0" width="6" height="6" fill="#e74c3c" stroke="#333" strokeWidth="0.1" />
          <rect x="1" y="1" width="4" height="4" fill="#fff" stroke="#333" strokeWidth="0.1" />
          <circle cx="2" cy="2" r="0.5" fill="#e74c3c" stroke="#333" strokeWidth="0.1" />
          <circle cx="4" cy="2" r="0.5" fill="#e74c3c" stroke="#333" strokeWidth="0.1" />
          <circle cx="2" cy="4" r="0.5" fill="#e74c3c" stroke="#333" strokeWidth="0.1" />
          <circle cx="4" cy="4" r="0.5" fill="#e74c3c" stroke="#333" strokeWidth="0.1" />

          {/* الأخضر */}
          <rect x="9" y="0" width="6" height="6" fill="#2ecc71" stroke="#333" strokeWidth="0.1" />
          <rect x="10" y="1" width="4" height="4" fill="#fff" stroke="#333" strokeWidth="0.1" />
          <circle cx="11" cy="2" r="0.5" fill="#2ecc71" stroke="#333" strokeWidth="0.1" />
          <circle cx="13" cy="2" r="0.5" fill="#2ecc71" stroke="#333" strokeWidth="0.1" />
          <circle cx="11" cy="4" r="0.5" fill="#2ecc71" stroke="#333" strokeWidth="0.1" />
          <circle cx="13" cy="4" r="0.5" fill="#2ecc71" stroke="#333" strokeWidth="0.1" />

          {/* الأصفر */}
          <rect x="0" y="9" width="6" height="6" fill="#f1c40f" stroke="#333" strokeWidth="0.1" />
          <rect x="1" y="10" width="4" height="4" fill="#fff" stroke="#333" strokeWidth="0.1" />
          <circle cx="2" cy="11" r="0.5" fill="#f1c40f" stroke="#333" strokeWidth="0.1" />
          <circle cx="4" cy="11" r="0.5" fill="#f1c40f" stroke="#333" strokeWidth="0.1" />
          <circle cx="2" cy="13" r="0.5" fill="#f1c40f" stroke="#333" strokeWidth="0.1" />
          <circle cx="4" cy="13" r="0.5" fill="#f1c40f" stroke="#333" strokeWidth="0.1" />

          {/* الأزرق */}
          <rect x="9" y="9" width="6" height="6" fill="#3498db" stroke="#333" strokeWidth="0.1" />
          <rect x="10" y="10" width="4" height="4" fill="#fff" stroke="#333" strokeWidth="0.1" />
          <circle cx="11" cy="11" r="0.5" fill="#3498db" stroke="#333" strokeWidth="0.1" />
          <circle cx="13" cy="11" r="0.5" fill="#3498db" stroke="#333" strokeWidth="0.1" />
          <circle cx="11" cy="13" r="0.5" fill="#3498db" stroke="#333" strokeWidth="0.1" />
          <circle cx="13" cy="13" r="0.5" fill="#3498db" stroke="#333" strokeWidth="0.1" />
          
          {/* مسارات الحركة */}
          <rect x="6" y="0" width="3" height="6" fill="#ecf0f1" stroke="#333" strokeWidth="0.1" />
          <rect x="6" y="9" width="3" height="6" fill="#ecf0f1" stroke="#333" strokeWidth="0.1" />
          <rect x="0" y="6" width="6" height="3" fill="#ecf0f1" stroke="#333" strokeWidth="0.1" />
          <rect x="9" y="6" width="6" height="3" fill="#ecf0f1" stroke="#333" strokeWidth="0.1" />
          
          {/* المنتصف */}
          <rect x="6" y="6" width="3" height="3" fill="#fff" stroke="#333" strokeWidth="0.1" />
          <polygon points="6,6 9,6 7.5,7.5" fill="#e74c3c" />
          <polygon points="9,6 9,9 7.5,7.5" fill="#2ecc71" />
          <polygon points="9,9 6,9 7.5,7.5" fill="#3498db" />
          <polygon points="6,9 6,6 7.5,7.5" fill="#f1c40f" />
        </svg>
      </div>

      {/* لوحة التحكم (النرد) */}
      <div className="ludo-controls">
        <div className="dice-display">{dice}</div>
        <button className="roll-btn" onClick={rollDice}>رمي النرد</button>
      </div>
    </div>
  );
}

export default Ludo;
