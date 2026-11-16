import React from 'react';

function Ludo({ onBack }) {
  return (
    <div className="ludo-container">
      <div className="ludo-header">
        <button className="back-btn" onClick={onBack}>رجوع</button>
        <h2>لعبة Ludo</h2>
      </div>
      
      {/* اللوحة المبدئية 15x15 */}
      <div className="ludo-board">
        {/* الأركان الأربعة (بيوت اللاعبين) */}
        <div className="home-base red-base"></div>
        <div className="home-base green-base"></div>
        <div className="home-base yellow-base"></div>
        <div className="home-base blue-base"></div>
        
        {/* مسار اللعب (سنبني تفاصيله لاحقاً) */}
        <div className="play-path">
          <div className="center-triangle"></div>
        </div>
      </div>
    </div>
  );
}

export default Ludo;
