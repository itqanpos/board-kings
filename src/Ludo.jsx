import React, { useState } from 'react';

function Ludo({ onBack }) {
  const [currentPlayer, setCurrentPlayer] = useState(0); // 0:Red, 1:Green, 2:Blue, 3:Yellow
  const [dice, setDice] = useState(0);
  const [hasRolled, setHasRolled] = useState(false);
  
  // حالة القطع (هل هي في البيت أم لا؟) - للتبسيط قطعة واحدة لكل لون
  const [tokens, setTokens] = useState({ red: true, green: true, blue: true, yellow: true });

  const colors = ['red', 'green', 'blue', 'yellow'];
  const hexColors = { red: '#e74c3c', green: '#2ecc71', blue: '#3498db', yellow: '#f1c40f' };
  const names = { 0: 'الأحمر', 1: 'الأخضر', 2: 'الأزرق', 3: 'الأصفر' };

  // إحداثيات البداية لكل لون
  const startCoords = {
    red: { x: 1.5, y: 6.5 },
    green: { x: 8.5, y: 1.5 },
    blue: { x: 13.5, y: 8.5 },
    yellow: { x: 6.5, y: 13.5 }
  };

  // إحداثيات البيت لكل لون
  const baseCoords = {
    red: { x: 2, y: 2 },
    green: { x: 13, y: 2 },
    blue: { x: 13, y: 13 },
    yellow: { x: 2, y: 13 }
  };

  // مسار الـ 52 مربع
  const path = [
    [1,6],[2,6],[3,6],[4,6],[5,6],[6,5],[6,4],[6,3],[6,2],[6,1],[7,0],[8,1],[8,2],[8,3],[8,4],[8,5],
    [9,6],[10,6],[11,6],[12,6],[13,6],[14,7],[13,8],[12,8],[11,8],[10,8],[9,8],[8,9],[8,10],[8,11],[8,12],[8,13],
    [7,14],[6,13],[6,12],[6,11],[6,10],[6,9],[5,8],[4,8],[3,8],[2,8],[1,8],[0,7]
  ];

  const rollDice = () => {
    if (hasRolled) return;
    const roll = Math.floor(Math.random() * 6) + 1;
    setDice(roll);
    setHasRolled(true);
  };

  const handleTokenClick = (color) => {
    if (currentPlayer !== colors.indexOf(color)) return;
    if (!hasRolled) return;
    
    // لو اللاعب رمى 6 والقطعة في البيت
    if (dice === 6 && tokens[color]) {
      setTokens({ ...tokens, [color]: false });
      endTurn(true); // ينهي الدور ويسمح له بالرمي تاني
    }
  };

  const endTurn = (extraTurn = false) => {
    setDice(0);
    setHasRolled(false);
    if (!extraTurn) {
      setCurrentPlayer((prev) => (prev + 1) % 4);
    }
  };

  return (
    <div className="ludo-container">
      <div className="ludo-header">
        <button className="back-btn" onClick={onBack}>رجوع</button>
        <div className="turn-indicator">
          دور: <span style={{ color: hexColors[colors[currentPlayer]] }}>{names[currentPlayer]}</span>
        </div>
      </div>
      
      <div className="ludo-board-wrapper">
        <svg viewBox="0 0 15 15" className="ludo-svg">
          <rect width="15" height="15" fill="#fff" stroke="#333" strokeWidth="0.1" />
          
          {/* رسم مسار الـ 52 مربع */}
          {path.map((pos, i) => (
            <rect key={i} x={pos[0]} y={pos[1]} width="1" height="1" fill="#ecf0f1" stroke="#333" strokeWidth="0.1" />
          ))}

          {/* مسارات النهاية (Home Paths) */}
          {[1,2,3,4,5].map(i => <rect key={`hr${i}`} x={i} y={7} width="1" height="1" fill="#e74c3c" stroke="#333" strokeWidth="0.1" />)}
          {[1,2,3,4,5].map(i => <rect key={`hg${i}`} x={7} y={i} width="1" height="1" fill="#2ecc71" stroke="#333" strokeWidth="0.1" />)}
          {[1,2,3,4,5].map(i => <rect key={`hb${i}`} x={14-i} y={7} width="1" height="1" fill="#3498db" stroke="#333" strokeWidth="0.1" />)}
          {[1,2,3,4,5].map(i => <rect key={`hy${i}`} x={7} y={14-i} width="1" height="1" fill="#f1c40f" stroke="#333" strokeWidth="0.1" />)}

          {/* المنازل الأربعة */}
          <rect x="0" y="0" width="6" height="6" fill="#e74c3c" stroke="#333" strokeWidth="0.1" />
          <rect x="1" y="1" width="4" height="4" fill="#fff" stroke="#333" strokeWidth="0.1" />
          
          <rect x="9" y="0" width="6" height="6" fill="#2ecc71" stroke="#333" strokeWidth="0.1" />
          <rect x="10" y="1" width="4" height="4" fill="#fff" stroke="#333" strokeWidth="0.1" />
          
          <rect x="0" y="9" width="6" height="6" fill="#f1c40f" stroke="#333" strokeWidth="0.1" />
          <rect x="1" y="10" width="4" height="4" fill="#fff" stroke="#333" strokeWidth="0.1" />
          
          <rect x="9" y="9" width="6" height="6" fill="#3498db" stroke="#333" strokeWidth="0.1" />
          <rect x="10" y="10" width="4" height="4" fill="#fff" stroke="#333" strokeWidth="0.1" />

          {/* المنتصف */}
          <polygon points="6,6 9,6 7.5,7.5" fill="#e74c3c" stroke="#333" strokeWidth="0.1"/>
          <polygon points="9,6 9,9 7.5,7.5" fill="#2ecc71" stroke="#333" strokeWidth="0.1"/>
          <polygon points="9,9 6,9 7.5,7.5" fill="#3498db" stroke="#333" strokeWidth="0.1"/>
          <polygon points="6,9 6,6 7.5,7.5" fill="#f1c40f" stroke="#333" strokeWidth="0.1"/>

          {/* القطع */}
          {colors.map(color => {
            const isHome = tokens[color];
            const pos = isHome ? baseCoords[color] : startCoords[color];
            return (
              <circle 
                key={color}
                cx={pos.x} cy={pos.y} r="0.4" 
                fill={hexColors[color]} stroke="#333" strokeWidth="0.1"
                className={`token ${currentPlayer === colors.indexOf(color) && hasRolled && dice === 6 && isHome ? 'clickable' : ''}`}
                onClick={() => handleTokenClick(color)}
              />
            );
          })}
        </svg>
      </div>

      <div className="ludo-controls">
        <div className="dice-display" style={{ color: dice > 0 ? hexColors[colors[currentPlayer]] : '#333' }}>
          {dice > 0 ? dice : '-'}
        </div>
        
        {!hasRolled ? (
          <button className="roll-btn" onClick={rollDice}>رمي النرد</button>
        ) : (
          <div className="action-buttons">
             {dice !== 6 && <button className="roll-btn" onClick={() => endTurn(false)}>إنهاء الدور</button>}
             {dice === 6 && <p className="hint-text">اختر قطعة للخروج أو إنهاء الدور</p>}
             {dice === 6 && <button className="roll-btn" onClick={() => endTurn(false)}>تخطي</button>}
          </div>
        )}
      </div>
    </div>
  );
}

export default Ludo;
