"""
Module for integrating with Julia and StateSpaceLearning.jl using JuliaCall
"""
from typing import Dict, Any
import pandas as pd
from pathlib import Path
import logging

logger = logging.getLogger(__name__)

# Try to import JuliaCall
try:
    from juliacall import Main as jl
    
    # Import the package
    jl.seval('using StateSpaceLearning')
    
    # Get the directory of the current file
    current_dir = Path(__file__).parent.absolute()
    
    # Include the getssl.jl file using an absolute path
    getssl = jl.include(str(current_dir / "getssl.jl"))
   
    JULIA_AVAILABLE = True
except ImportError:
    JULIA_AVAILABLE = False
    logger.warning("JuliaCall is not installed. Julia integration will be disabled.")

def run_structural_model(price_data: pd.DataFrame) -> Dict[str, Any]:
    """
    Runs the state-space structural model on the given price data using Julia.

    This function iterates over each ticker (column) in the price data,
    converts the price series to a Julia-compatible format, and calls the
    `getssl.jl` script to perform the analysis.

    Args:
        price_data: A pandas DataFrame where each column represents a ticker's
                    price series and the index is the date.

    Returns:
        A dictionary where keys are ticker symbols and values are dictionaries
        containing the model's output, including the 'trend' series.
        If Julia is not available, raises a RuntimeError.
    """
    if not JULIA_AVAILABLE:
        raise RuntimeError("Julia integration is not available. Please install PyJulia.")
    
    results = {}
    
    # Process each ticker separately
    for ticker in price_data.columns:
        try:
            # Get the price series for this ticker
            prices = price_data[ticker].dropna().values.astype(float)
            
            # Run the Julia function
            result = getssl(prices)
            
            # Check if the result is valid
            if not result.get('success', False):
                logger.warning(f"Analysis failed for {ticker}: {result.get('message', 'Unknown error')}")
                continue
            results[ticker] = result
        except Exception as e:
            logger.error(f"Error processing {ticker}: {str(e)}")
            results[ticker] = {
                'success': False,
                'message': f"Error processing {ticker}: {str(e)}"
            }
    
    return results
