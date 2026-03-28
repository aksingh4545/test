# 🐍 Medium Level Python Practice Roadmap

This roadmap is designed to strengthen your Python programming skills through hands-on practice. Each topic includes key concepts and practice questions to solidify your understanding.

---

## 📋 Table of Contents

1. [Data Structures Deep Dive](#1-data-structures-deep-dive)
2. [Functions & Functional Programming](#2-functions--functional-programming)
3. [Object-Oriented Programming (OOP)](#3-object-oriented-programming-oop)
4. [Error Handling & Debugging](#4-error-handling--debugging)
5. [File Handling & Working with Data](#5-file-handling--working-with-data)
6. [Modules & Packages](#6-modules--packages)
7. [Iterators, Generators & Decorators](#7-iterators-generators--decorators)
8. [Regular Expressions](#8-regular-expressions)
9. [Working with APIs & JSON](#9-working-with-apis--json)
10. [Testing & Best Practices](#10-testing--best-practices)

---

## 1. Data Structures Deep Dive

### Key Concepts
- List comprehensions and nested comprehensions
- Dictionary operations and use cases
- Sets and set operations (union, intersection, difference)
- Tuples and their immutability
- When to use each data structure
- `collections` module (`Counter`, `defaultdict`, `namedtuple`, `deque`)

### Practice Questions

#### Easy-Medium
1. **List Manipulation**: Write a function that takes a list of integers and returns a new list with only the even numbers squared.
2. **Dictionary Operations**: Create a function that counts the frequency of each character in a string and returns it as a dictionary.
3. **Set Operations**: Given two lists, find their common elements without duplicates using sets.

#### Medium
4. **Nested List Processing**: Flatten a nested list of arbitrary depth using recursion or iteration.
5. **Dictionary Grouping**: Group a list of dictionaries by a specific key (e.g., group students by their grade).
6. **Two Sum Problem**: Given a list of numbers and a target, find two numbers that add up to the target. Return their indices.

#### Challenge
7. **LRU Cache Implementation**: Implement a Least Recently Used (LRU) cache using `OrderedDict` or `deque`.
8. **Anagram Checker**: Write a function to check if two strings are anagrams using `Counter`.
9. **Valid Parentheses**: Check if a string of parentheses `()[]{}` is valid using a stack (list).

---

## 2. Functions & Functional Programming

### Key Concepts
- `*args` and `**kwargs`
- Lambda functions
- `map()`, `filter()`, `reduce()`
- First-class functions
- Closures
- `functools` module

### Practice Questions

#### Easy-Medium
1. **Variable Arguments**: Create a function that accepts any number of arguments and returns their sum.
2. **Lambda Practice**: Convert a regular function that multiplies two numbers into a lambda function.
3. **Map & Filter**: Use `map()` to convert a list of temperatures from Celsius to Fahrenheit. Use `filter()` to find numbers greater than 50.

#### Medium
4. **Function Factory**: Create a function that returns another function (closure) that adds a specific number to its input.
5. **Reduce Implementation**: Use `reduce()` to find the product of all elements in a list.
6. **Keyword Arguments**: Write a function that accepts keyword arguments and prints them in a formatted way.

#### Challenge
7. **Memoization**: Implement a memoization decorator to cache results of expensive function calls.
8. **Function Composition**: Create a function that composes two functions (f(g(x))).
9. **Partial Functions**: Use `functools.partial` to create a specialized version of a function with some arguments pre-filled.

---

## 3. Object-Oriented Programming (OOP)

### Key Concepts
- Classes and objects
- Instance vs class vs static methods
- Inheritance and multiple inheritance
- Encapsulation (public, protected, private)
- Polymorphism
- Magic/Dunder methods (`__str__`, `__repr__`, `__eq__`, etc.)
- Properties and decorators (`@property`)
- Abstract base classes

### Practice Questions

#### Easy-Medium
1. **Basic Class**: Create a `BankAccount` class with methods to deposit, withdraw, and check balance.
2. **Class Attributes**: Create a `Person` class with class attribute to count total persons created.
3. **String Representation**: Implement `__str__` and `__repr__` for a `Book` class.

#### Medium
4. **Inheritance**: Create a base class `Shape` and derived classes `Circle`, `Rectangle`, `Triangle` with `area()` and `perimeter()` methods.
5. **Encapsulation**: Create a `Student` class with private attributes and property decorators for validation.
6. **Operator Overloading**: Implement `__add__`, `__sub__`, `__eq__` for a `Vector` class.

#### Challenge
7. **Multiple Inheritance**: Create a `SmartPhone` class that inherits from both `Phone` and `Camera` classes.
8. **Abstract Base Class**: Create an abstract base class `Payment` with abstract methods `process_payment()` and `refund()`.
9. **Context Manager**: Create a class-based context manager for database connections.

---

## 4. Error Handling & Debugging

### Key Concepts
- `try`, `except`, `else`, `finally`
- Raising exceptions
- Custom exceptions
- Exception hierarchy
- Logging basics
- Debugging techniques

### Practice Questions

#### Easy-Medium
1. **Basic Exception Handling**: Write a function that divides two numbers and handles `ZeroDivisionError`.
2. **Multiple Exceptions**: Handle multiple exceptions when converting user input to an integer.
3. **Finally Block**: Create a function that opens a file and ensures it's closed using `finally`.

#### Medium
4. **Custom Exception**: Create a custom exception `InvalidAgeError` that raises when age is negative or above 150.
5. **Exception Chaining**: Write code that catches an exception and raises a new one while preserving the original traceback.
6. **Input Validation**: Create a function that validates email format and raises `ValueError` for invalid emails.

#### Challenge
7. **Retry Decorator**: Create a decorator that retries a function n times before raising an exception.
8. **Context Manager with Error Handling**: Create a context manager that handles specific exceptions and logs them.
9. **Robust API Wrapper**: Build a wrapper for API calls with proper error handling, retries, and logging.

---

## 5. File Handling & Working with Data

### Key Concepts
- Reading and writing files
- Working with CSV files
- JSON serialization/deserialization
- Context managers (`with` statement)
- `pathlib` module
- Binary files

### Practice Questions

#### Easy-Medium
1. **File Reader**: Write a function that reads a file and returns the number of lines, words, and characters.
2. **CSV Operations**: Read a CSV file and calculate the average of a numeric column.
3. **JSON Handling**: Read a JSON file, modify some data, and write it back.

#### Medium
4. **File Merger**: Write a program that merges multiple text files into one with separators.
5. **Log File Analyzer**: Parse a log file and extract all error messages with timestamps.
6. **Data Export**: Create a program that reads data from CSV and exports it to JSON format.

#### Challenge
7. **Large File Processing**: Process a large file line by line without loading it entirely into memory.
8. **File Backup System**: Create a script that backs up files with timestamps in filenames.
9. **Configuration Manager**: Build a class that manages configuration stored in JSON with validation.

---

## 6. Modules & Packages

### Key Concepts
- Creating modules and packages
- `__init__.py` and its purpose
- Import statements (absolute vs relative)
- `__name__ == "__main__"`
- `__all__` for controlling exports
- Virtual environments
- `pip` and package management

### Practice Questions

#### Easy-Medium
1. **Create a Module**: Create a module with utility functions (string, math operations) and import it.
2. **Package Structure**: Create a package with multiple modules and an `__init__.py` file.
3. **Main Guard**: Write a script that demonstrates the use of `if __name__ == "__main__"`.

#### Medium
4. **Relative Imports**: Create a package with subpackages and demonstrate relative imports.
5. **Custom Package**: Build a package for mathematical operations with proper `__all__` definition.
6. **Setup.py**: Create a `setup.py` file for your custom package.

#### Challenge
7. **Plugin System**: Design a simple plugin system where modules can be dynamically loaded.
8. **Package with CLI**: Create a package that can be installed and used from command line.
9. **Dependency Management**: Create a `requirements.txt` and manage package versions properly.

---

## 7. Iterators, Generators & Decorators

### Key Concepts
- Iterables vs iterators
- `iter()` and `next()`
- Generator functions (`yield`)
- Generator expressions
- Decorator syntax
- Decorators with arguments
- `@wraps` decorator

### Practice Questions

#### Easy-Medium
1. **Custom Iterator**: Create a class that implements `__iter__` and `__next__` for Fibonacci sequence.
2. **Simple Generator**: Write a generator that yields squares of numbers from 1 to n.
3. **Generator Expression**: Convert a list comprehension to a generator expression.

#### Medium
4. **Range Generator**: Create a generator that mimics the built-in `range()` function.
5. **Chaining Generators**: Create multiple generators and chain them together.
6. **Timer Decorator**: Write a decorator that measures the execution time of a function.

#### Challenge
7. **Infinite Sequence**: Create an infinite generator for prime numbers.
8. **Decorator Factory**: Create a decorator that accepts arguments (e.g., number of retries).
9. **Coroutines**: Implement a simple coroutine-based pipeline for data processing.

---

## 8. Regular Expressions

### Key Concepts
- `re` module basics
- Pattern matching and searching
- Character classes and quantifiers
- Groups and capturing
- Lookahead and lookbehind
- Common patterns (email, phone, URL)

### Practice Questions

#### Easy-Medium
1. **Pattern Matching**: Write a regex to check if a string contains only alphanumeric characters.
2. **Find All Matches**: Extract all numbers from a string using regex.
3. **Email Validation**: Create a pattern to validate basic email format.

#### Medium
4. **Phone Number Extractor**: Extract phone numbers in various formats from text.
5. **HTML Tag Parser**: Extract content between HTML tags using regex.
6. **Date Format Converter**: Find dates in DD/MM/YYYY format and convert to YYYY-MM-DD.

#### Challenge
7. **Password Validator**: Create a regex that validates password strength (length, uppercase, lowercase, numbers, special chars).
8. **URL Extractor**: Extract all URLs from a text including query parameters.
9. **Log Parser**: Parse structured log entries and extract timestamp, level, and message.

---

## 9. Working with APIs & JSON

### Key Concepts
- HTTP methods (GET, POST, PUT, DELETE)
- `requests` library
- REST API concepts
- Authentication (API keys, tokens)
- JSON parsing and building
- Error handling for API calls

### Practice Questions

#### Easy-Medium
1. **GET Request**: Fetch data from a public API (e.g., JSONPlaceholder) and display it.
2. **Query Parameters**: Make a GET request with query parameters.
3. **JSON Parsing**: Parse JSON response and extract specific fields.

#### Medium
4. **POST Request**: Send data to an API and handle the response.
5. **API Wrapper Class**: Create a class that wraps API calls with error handling.
6. **Pagination Handler**: Handle paginated API responses and collect all data.

#### Challenge
7. **Rate Limiter**: Implement rate limiting for API calls.
8. **Async API Calls**: Use `aiohttp` to make concurrent API requests.
9. **API Data Pipeline**: Build a pipeline that fetches, processes, and stores API data.

---

## 10. Testing & Best Practices

### Key Concepts
- Unit testing with `unittest`
- `pytest` basics
- Test fixtures
- Mocking and patching
- Code coverage
- PEP 8 style guide
- Type hints
- Documentation (docstrings)

### Practice Questions

#### Easy-Medium
1. **Basic Unit Test**: Write unit tests for a simple calculator function using `unittest`.
2. **Test Fixtures**: Create test fixtures for setting up test data.
3. **PEP 8 Compliance**: Refactor code to follow PEP 8 guidelines.

#### Medium
4. **Pytest Conversion**: Convert `unittest` tests to `pytest` style.
5. **Mocking External Calls**: Write tests that mock API calls or file operations.
6. **Parameterized Tests**: Create parameterized tests for multiple input scenarios.

#### Challenge
7. **Test Coverage**: Achieve 90%+ code coverage for a module.
8. **Integration Tests**: Write integration tests for a multi-component system.
9. **Type Annotated Code**: Add type hints to existing code and verify with `mypy`.

---

## 🎯 Capstone Projects

Combine multiple concepts by building these projects:

1. **Task Management CLI**: A command-line task manager with file storage, categories, and due dates.
2. **Weather Dashboard**: Fetch weather data from an API and display it with caching.
3. **Expense Tracker**: Track expenses with categories, generate reports, and export to CSV/JSON.
4. **URL Shortener**: Create a URL shortening service with persistence.
5. **Blog Engine**: A simple blog system with posts, comments, and user management.

---

## 📚 Additional Resources

- [Python Official Documentation](https://docs.python.org/3/)
- [Real Python](https://realpython.com/)
- [Python Cookbook](https://www.oreilly.com/library/view/python-cookbook/0596001673/)
- [Fluent Python](https://www.oreilly.com/library/view/fluent-python-2nd/9781492056348/)
- [LeetCode Python Problems](https://leetcode.com/problemset/all/?tags=python)
- [HackerRank Python](https://www.hackerrank.com/domains/python)

---

## 💡 Tips for Success

1. **Code Daily**: Practice consistently, even if it's just 30 minutes.
2. **Read Others' Code**: Study open-source Python projects on GitHub.
3. **Write Tests**: Always write tests for your code.
4. **Use Version Control**: Practice Git with every project.
5. **Document Your Learning**: Keep notes of concepts and solutions.
6. **Review & Refactor**: Revisit old code and improve it.
7. **Join Communities**: Participate in Python forums and discussions.

---

**Happy Coding! 🚀**
