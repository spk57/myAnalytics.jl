#!/usr/bin/env Rscript
# test_r.R - Simple R script to test R running in Cursor
# Usage: Rscript test_r.R

cat("=== R Test Script ===\n\n")

# Test 1: Basic calculations
cat("Test 1: Basic Calculations\n")
x <- 10
y <- 20
result <- x + y
cat(sprintf("  %d + %d = %d\n", x, y, result))
cat("  ✓ Pass\n\n")

# Test 2: Vector operations
cat("Test 2: Vector Operations\n")
numbers <- c(1, 2, 3, 4, 5)
squared <- numbers^2
cat("  Original:", numbers, "\n")
cat("  Squared: ", squared, "\n")
cat("  ✓ Pass\n\n")

# Test 3: Data frame creation
cat("Test 3: Data Frame Creation\n")
df <- data.frame(
  id = 1:5,
  name = c("Alice", "Bob", "Charlie", "Diana", "Eve"),
  score = c(85, 92, 78, 96, 88)
)
cat("  Created data frame with", nrow(df), "rows and", ncol(df), "columns\n")
cat("  First few rows:\n")
print(head(df, 3))
cat("  ✓ Pass\n\n")

# Test 4: Statistical operations
cat("Test 4: Statistical Operations\n")
scores <- df$score
cat("  Mean score:", mean(scores), "\n")
cat("  Median score:", median(scores), "\n")
cat("  Standard deviation:", round(sd(scores), 2), "\n")
cat("  ✓ Pass\n\n")

# Test 5: String operations
cat("Test 5: String Operations\n")
greeting <- "Hello, R!"
cat("  ", greeting, "\n")
cat("  Length:", nchar(greeting), "characters\n")
cat("  Uppercase:", toupper(greeting), "\n")
cat("  ✓ Pass\n\n")

# Test 6: Date operations
cat("Test 6: Date Operations\n")
today <- Sys.Date()
cat("  Today's date:", format(today, "%Y-%m-%d"), "\n")
cat("  Day of week:", weekdays(today), "\n")
cat("  ✓ Pass\n\n")

# Summary
cat("=== All Tests Passed! ===\n")
cat("R is working correctly in Cursor.\n")
