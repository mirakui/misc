const { useState } = React;

function Calculator() {
    const [display, setDisplay] = useState('0');
    const [previousValue, setPreviousValue] = useState(null);
    const [operation, setOperation] = useState(null);
    const [waitingForNewValue, setWaitingForNewValue] = useState(false);

    const inputNumber = (num) => {
        if (waitingForNewValue) {
            setDisplay(String(num));
            setWaitingForNewValue(false);
        } else {
            setDisplay(display === '0' ? String(num) : display + num);
        }
    };

    const inputDecimal = () => {
        if (waitingForNewValue) {
            setDisplay('0.');
            setWaitingForNewValue(false);
        } else if (display.indexOf('.') === -1) {
            setDisplay(display + '.');
        }
    };

    const clear = () => {
        setDisplay('0');
        setPreviousValue(null);
        setOperation(null);
        setWaitingForNewValue(false);
    };

    const performOperation = (nextOperation) => {
        const inputValue = parseFloat(display);

        if (previousValue === null) {
            setPreviousValue(inputValue);
        } else if (operation) {
            const currentValue = previousValue || 0;
            const newValue = calculate(currentValue, inputValue, operation);

            setDisplay(String(newValue));
            setPreviousValue(newValue);
        }

        setWaitingForNewValue(true);
        setOperation(nextOperation);
    };

    const calculate = (firstValue, secondValue, operation) => {
        switch (operation) {
            case '+':
                return firstValue + secondValue;
            case '-':
                return firstValue - secondValue;
            case '*':
                return firstValue * secondValue;
            case '/':
                return firstValue / secondValue;
            case '=':
                return secondValue;
            default:
                return secondValue;
        }
    };

    const handleOperationClick = (op) => {
        performOperation(op);
    };

    return (
        <div className="calculator">
            <style jsx>{`
                .calculator {
                    background: rgba(255, 255, 255, 0.95);
                    border-radius: 20px;
                    box-shadow: 0 20px 40px rgba(0, 0, 0, 0.2);
                    padding: 30px;
                    width: 320px;
                }

                .display {
                    background: #2d3748;
                    color: white;
                    font-size: 36px;
                    font-weight: 300;
                    padding: 20px;
                    text-align: right;
                    margin-bottom: 20px;
                    border-radius: 10px;
                    box-shadow: inset 0 2px 5px rgba(0, 0, 0, 0.3);
                    min-height: 50px;
                    overflow: hidden;
                    text-overflow: ellipsis;
                }

                .button-grid {
                    display: grid;
                    grid-template-columns: repeat(4, 1fr);
                    gap: 10px;
                }

                .btn {
                    background: #e2e8f0;
                    border: none;
                    border-radius: 10px;
                    color: #2d3748;
                    cursor: pointer;
                    font-size: 20px;
                    font-weight: 500;
                    padding: 20px;
                    transition: all 0.2s ease;
                    outline: none;
                }

                .btn:hover {
                    background: #cbd5e0;
                    transform: translateY(-2px);
                    box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
                }

                .btn:active {
                    transform: translateY(0);
                    box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
                }

                .btn-number {
                    background: #4a5568;
                    color: white;
                }

                .btn-number:hover {
                    background: #2d3748;
                }

                .btn-operator {
                    background: #805ad5;
                    color: white;
                }

                .btn-operator:hover {
                    background: #6b46c1;
                }

                .btn-clear {
                    background: #f56565;
                    color: white;
                    grid-column: span 2;
                }

                .btn-clear:hover {
                    background: #e53e3e;
                }

                .btn-equals {
                    background: #48bb78;
                    color: white;
                    grid-column: span 2;
                }

                .btn-equals:hover {
                    background: #38a169;
                }

                .btn-zero {
                    grid-column: span 2;
                }
            `}</style>
            
            <div className="display">{display}</div>
            
            <div className="button-grid">
                <button className="btn btn-clear" onClick={clear}>Clear</button>
                <button className="btn btn-operator" onClick={() => handleOperationClick('/')}>/</button>
                <button className="btn btn-operator" onClick={() => handleOperationClick('*')}>×</button>
                
                <button className="btn btn-number" onClick={() => inputNumber(7)}>7</button>
                <button className="btn btn-number" onClick={() => inputNumber(8)}>8</button>
                <button className="btn btn-number" onClick={() => inputNumber(9)}>9</button>
                <button className="btn btn-operator" onClick={() => handleOperationClick('-')}>-</button>
                
                <button className="btn btn-number" onClick={() => inputNumber(4)}>4</button>
                <button className="btn btn-number" onClick={() => inputNumber(5)}>5</button>
                <button className="btn btn-number" onClick={() => inputNumber(6)}>6</button>
                <button className="btn btn-operator" onClick={() => handleOperationClick('+')}>+</button>
                
                <button className="btn btn-number" onClick={() => inputNumber(1)}>1</button>
                <button className="btn btn-number" onClick={() => inputNumber(2)}>2</button>
                <button className="btn btn-number" onClick={() => inputNumber(3)}>3</button>
                <button className="btn btn-equals" onClick={() => handleOperationClick('=')} style={{gridRow: 'span 2'}}>=</button>
                
                <button className="btn btn-number btn-zero" onClick={() => inputNumber(0)}>0</button>
                <button className="btn btn-number" onClick={inputDecimal}>.</button>
            </div>
        </div>
    );
}

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<Calculator />);