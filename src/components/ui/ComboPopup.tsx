import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';

interface ComboPopupProps {
  combo: number;
  player: 1 | 2;
  visible: boolean;
  hitResult?: 'PERFECT' | 'GREAT' | 'GOOD' | 'MISS';
}

export const ComboPopup: React.FC<ComboPopupProps> = ({ 
  combo, 
  player, 
  visible, 
  hitResult 
}) => {
  const getComboColor = (combo: number) => {
    if (combo >= 50) return '#FF6B6B'; // Red for amazing combo
    if (combo >= 20) return '#4ECDC4'; // Teal for great combo
    if (combo >= 10) return '#45B7D1'; // Blue for good combo
    return '#95E1D3'; // Light green for starting combo
  };

  const getHitColor = (result?: string) => {
    switch (result) {
      case 'PERFECT': return '#FFD700';
      case 'GREAT': return '#32CD32';
      case 'GOOD': return '#FFA500';
      case 'MISS': return '#FF4444';
      default: return '#FFFFFF';
    }
  };

  return (
    <AnimatePresence>
      {visible && combo > 0 && (
        <motion.div
          initial={{ opacity: 0, scale: 0.5, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.5, y: -20 }}
          transition={{ duration: 0.3, ease: "backOut" }}
          className="combo-popup"
          style={{
            position: 'fixed',
            top: '20%',
            left: player === 1 ? '25%' : '75%',
            transform: 'translateX(-50%)',
            zIndex: 1000,
            textAlign: 'center',
            pointerEvents: 'none'
          }}
        >
          {/* Hit Result */}
          {hitResult && (
            <motion.div
              initial={{ opacity: 0, scale: 2 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: 0.2 }}
              style={{
                fontSize: '24px',
                fontWeight: 'bold',
                color: getHitColor(hitResult),
                textShadow: '0 0 10px rgba(255,255,255,0.5)',
                marginBottom: '8px'
              }}
            >
              {hitResult}
            </motion.div>
          )}

          {/* Combo Count */}
          <motion.div
            initial={{ opacity: 0, rotateZ: -10 }}
            animate={{ opacity: 1, rotateZ: 0 }}
            transition={{ delay: 0.1, duration: 0.3 }}
            style={{
              fontSize: combo >= 50 ? '32px' : combo >= 20 ? '28px' : '24px',
              fontWeight: 'bold',
              color: getComboColor(combo),
              textShadow: `0 0 20px ${getComboColor(combo)}`,
              filter: 'drop-shadow(0 0 10px rgba(0,0,0,0.5))'
            }}
          >
            {combo} COMBO!
          </motion.div>

          {/* Special effects for high combos */}
          {combo >= 50 && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: [0, 1, 0] }}
              transition={{ duration: 0.5, repeat: Infinity }}
              style={{
                fontSize: '16px',
                color: '#FFD700',
                marginTop: '4px',
                fontWeight: 'bold'
              }}
            >
              ¡INCREÍBLE!
            </motion.div>
          )}
          
          {combo >= 20 && combo < 50 && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              style={{
                fontSize: '14px',
                color: '#4ECDC4',
                marginTop: '4px'
              }}
            >
              ¡Excelente!
            </motion.div>
          )}
        </motion.div>
      )}
    </AnimatePresence>
  );
};
