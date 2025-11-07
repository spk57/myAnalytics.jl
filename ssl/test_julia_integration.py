"""
Test the full Julia integration with the main application logic.

This script simulates the main workflow of the eapy application:
- It checks if Julia is available.
- Creates a sample DataFrame with stock prices.
- Calls the `run_structural_model` function to perform analysis.
- Verifies that the results are in the expected format.

This test ensures that the Python-to-Julia bridge is working correctly and that
the data is being passed and returned as expected.

Usage:
    python tests/test_julia_integration.py
"""
import os
import sys
import pandas as pd
import logging
from juliacall import Main as jl
#jl.seval('using StateSpaceLearning')
from  juliacall_integration import run_structural_model, JULIA_AVAILABLE


# Configure logging for tests
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)
JULIA_AVAILABLE = True

# Add the project root to the Python path to allow module imports
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)

# Now that the path is set, we can import the necessary functions

def main():
    """Main function to run the Julia integration test."""
    logger.info("Testing Julia integration...")

    if not JULIA_AVAILABLE:
        logger.info("Julia is not available. Skipping test.")
        sys.exit(0)

    # Create a sample DataFrame
    data = {
        'AAPL': [150.0, 151.0, 152.5, 153.0, 154.5, 155.0, 156.5, 157.0, 158.5, 159.0, 160.5, 161.0, 162.5, 163.0, 164.5, 165.0, 166.5, 167.0, 168.5, 169.0, 170.5, 171.0, 172.5, 173.0, 174.5, 175.0, 176.5, 177.0, 178.5, 179.0, 180.5],
        'MSFT': [300.0, 301.5, 303.0, 304.5, 305.0, 306.5, 307.0, 308.5, 309.0, 310.5, 311.0, 312.5, 313.0, 314.5, 315.0, 316.5, 317.0, 318.5, 319.0, 320.5, 321.0, 322.5, 323.0, 324.5, 325.0, 326.5, 327.0, 328.5, 329.0, 330.5, 331.0]
    }
    price_data = pd.DataFrame(data)

    # Run the structural model
    try:
        results = run_structural_model(price_data)
        logger.info("Successfully ran structural model.")
        
        # Verify results
        assert isinstance(results, dict)
        assert 'AAPL' in results
        assert 'trend' in results['AAPL']
        logger.info("Test passed: Results are in the expected format.")

    except Exception as e:
        logger.error(f"An error occurred during the test: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()