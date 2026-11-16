import React, { useState } from 'react';
import { COLORS, HEX, NAMES, SAFE_SPOTS, getTokenCoords, getInitialTokens } from './ludoEngine';

function Ludo({ onBack }) {
  const [tokens, setTokens] = useState(getInitialTokens());
  const [currentPlayer, setCurrentPlayer] = useState(0);
  const [dice, setDice] = useState(0);
  const [hasRolled, setHasRolled] = useState(false);
  const [sixCount, setSixCount] = useState(0);
  const [message, setMessage] = useState('');

  const rollDice = () => {
    if (hasRolled) return;
    const roll = Math.floor(Math.random() * 6) + 1;
    
    let newSixCount = sixCount;
    if (roll === 6) {
      newSixCount++;
      if (newSixCount === 3) {
        setMessage('3 رميات 6! خسرت الدور.');
        setTimeout(() => endTurn(), 1500);
        return;
      }
    } else {
      newSixCount = 0;
    }

    setDice(roll);
    setHasRolled(true);
    setSixCount(newSixCount);
    setMessage('');

    // لو مفيش أي حركة متاحة، ننهي الدور تلقائياً
    const hasValidMove = tokens.some(t => 
      t.color === COLORS[currentPlayer] && 
      (t.pos === -1 ? roll === 6 : t.pos + roll <= 57)
    );
    
    if (!hasValidMove) {
      setMessage('لا توجد حركات متاحة');
      setTimeout(() => endTurn(), 1500);
    }
  };

  const endTurn = (extraTurn = false) => {
    setDice(0);
    setHasRolled(false);
    if (!extraTurn) {
      setCurrentPlayer((prev) => (prev + 1) % 4);
      setSixCount(0); // تصفير عداد الـ6 لو الدور اتغير
    }
  };

  const moveToken = (tokenId) => {
    if (!hasRolled) return;
    
    setTokens(prevTokens => {
      let newTokens = [...prevTokens];
      let token = newTokens.find(t => t.id === tokenId);
      
      // لو القطعة في البيت ورمى 6
      if (token.pos === -1 && dice === 6) {
        token.pos = 0; // يطلع لخط البداية
      } 
      // لو القطعة على الشاشة
      else if (token.pos !== -1) {
        if (token.pos + dice > 57) return prevTokens; // حركة غير قانونية
        token.pos += dice;
      }

      // التحقق من الأكل (Capture)
      if (token.pos < 52) {
        const absPos = (token.pos + (token.color === 'red' ? 0 : token.color === 'green' ? 13 : token.color === 'blue' ? 26 : 39)) % 52;
        
        // لو الخانة مش آمنة، ياكل أي خصم عليها
        if (!SAFE_SPOTS.includes(absPos)) {
          newTokens.forEach(t => {
            if (t.color !== token.color && t.pos !== -1 && t.pos < 52) {
               const tAbsPos = (t.pos + (t.color === 'red' ? 0 : t.color === 'green' ? 13 : t.color === 'blue' ? 26 : 39)) % 52;
               if (tAbsPos === absPos) {
                 t.pos = -1; // رجوع للبيت
                 setMessage(`تم أكل قطعة ${NAMES[t.index]}!`);
               }
            }
          });
        }
      }
      return newTokens;
    });

    // لو اللاعب خلص كل قطعه (وصلوا 57)
    const playerTokens = tokens.filter(t => t.color === COLORS[currentPlayer]);
    if (playerTokens.every(t => t.pos === 57)) {
      setMessage(`🎉 مبروك ${NAMES[currentPlayer]} فاز باللعبة!`);
      return;
    }

    endTurn(dice === 6); // لو رمى 6 يلعب تاني
  };

  return (
    <div className="ludo-container">
      <div className="ludo-header">
        <button className="back-btn" onClick={onBack}>رجوع</button>
        <div className="turn-indicator">
          دور: <span style={{ color: HEX[COLORS[currentPlayer]] }}>{NAMES[currentPlayer]}</span>
        </div>
      </div>
      
      <div className="ludo-board-wrapper">
        <svg viewBox="0 0 15 15" className="ludo-svg">
          <rect width="15" height="15" fill="#fff" stroke="#333" strokeWidth="0.1" />
          
          {/* مسار اللعب الرئيسي */}
          {[...Array(52)].map((_, i) => {
             // بنرسم المسار
             const [x, y] = getTokenCoords('red', i, 0); // نستخدم دالة الإحداثيات لأي لون عشان نرسم الخط
             return <rect key={i} x={x} y={y} width="1" height="1" fill="#ecf0f1" stroke="#333" strokeWidth="0.1" />;
          })}

          {/* مسارات النهاية */}
          {COLORS.map(c => [0,1,2,3,4].map(i => {
             const [x, y] = getTokenCoords(c, 52+i, 0);
             return <rect key={`${c}-home-${i}`} x={x} y={y} width="1" height="1" fill={HEX[c]} stroke="#333" strokeWidth="0.1" />;
          }))}

          {/* البيوت */}
          {COLORS.map(c => (
             <g key={`base-${c}`}>
               <rect x={c === 'red' || c === 'yellow' ? 0 : 9} y={c === 'red' || c === 'green' ? 0 : 9} width="6" height="6" fill={HEX[c]} stroke="#333" strokeWidth="0.1" />
               <rect x={c === 'red' || c === 'yellow' ? 1 : 10} y={c === 'red' || c === 'green' ? 1 : 10} width="4" height="4" fill="#fff" stroke="#333" strokeWidth="0.1" />
             </g>
          ))}

          {/* المنتصف */}
          <polygon points="6,6 9,6 7.5,7.5" fill="#e74c3c" stroke="#333" strokeWidth="0.1"/>
          <polygon points="9,6 9,9 7.5,7.5" fill="#2ecc71" stroke="#333" strokeWidth="0.1"/>
          <polygon points="9,9 6,9 7.5,7.5" fill="#3498db" stroke="#333" strokeWidth="0.1"/>
          <polygon points="6,9 6,6 7.5,7.5" fill="#f1c40f" stroke="#333" strokeWidth="0.1"/>

          {/* رسم كل القطع الـ 16 */}
          {tokens.map(t => {
            const [cx, cy] = getTokenCoords(t.color, t.pos, parseInt(t.id.split('-')[1]));
            const isMyTurn = t.color === COLORS[currentPlayer];
            const canMove = isMyTurn && hasRolled && (t.pos === -1 ? dice === 6 : t.pos + dice <= 57);
            
            return (
              <circle 
                key={t.id}
                cx={cx} cy={cy} r="0.4" 
                fill={HEX[t.color]} stroke="#333" strokeWidth="0.1"
                className={`token ${canMove ? 'clickable' : ''}`}
                onClick={() => canMove && moveToken(t.id)}
              />
            );
          })}
        </svg>
      </div>

      <div className="ludo-controls">
        <div className="dice-display" style={{ color: dice > 0 ? HEX[COLORS[currentPlayer]] : '#333' }}>
          {dice > 0 ? dice : '-'}
        </div>
        
        {message && <p className="message-text">{message}</p>}

        {!hasRolled ? (
          <button className="roll-btn" onClick={rollDice}>رمي النرد</button>
        ) : (
          <button className="roll-btn" onClick={() => endTurn(false)}>إنهاء الدور</button>
        )}
      </div>
    </div>
  );
}

export default Ludo;
