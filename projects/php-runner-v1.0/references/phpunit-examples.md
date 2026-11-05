# PHPUnit 13.x Examples

> Companion to `install_phpunit.sh`. PHPUnit 13 officially supports PHP 8.4 and 8.5.
> Source: <https://phpunit.de/getting-started/phpunit-13.html>

## Basic test class

```php
<?php
namespace App\Test;

use PHPUnit\Framework\TestCase;
use App\Calculator;

class CalculatorTest extends TestCase
{
    public function testAdd(): void
    {
        $calc = new Calculator();
        $this->assertSame(5, $calc->add(2, 3));
    }
}
```

Run: `php vendor/bin/phpunit tests/CalculatorTest.php`

## Data providers

```php
<?php
use PHPUnit\Framework\TestCase;

class NumberTest extends TestCase
{
    /**
     * @dataProvider provideNumbers
     */
    public function testIsEven(int $number, bool $expected): void
    {
        $this->assertSame($expected, $number % 2 === 0);
    }

    public static function provideNumbers(): array
    {
        return [
            'even positive'  => [2, true],
            'odd positive'   => [3, false],
            'zero'           => [0, true],
            'negative even'  => [-4, true],
            'negative odd'   => [-7, false],
        ];
    }
}
```

## Expecting exceptions

```php
<?php
public function testDivideByZeroThrows(): void
{
    $calc = new Calculator();
    $this->expectException(\InvalidArgumentException::class);
    $this->expectExceptionMessage('Cannot divide by zero');
    $calc->divide(1, 0);
}
```

## Mocking (PHPUnit 13 uses #[Attribute] instead of annotations)

```php
<?php
use PHPUnit\Framework\TestCase;
use PHPUnit\Framework\Attributes\MockClassName;
use App\Service\UserService;
use App\Repository\UserRepository;

class UserServiceTest extends TestCase
{
    public function testGetUserReturnsUser(): void
    {
        // Create mock of UserRepository
        $repo = $this->createMock(UserRepository::class);
        $repo->method('findById')
             ->with(42)
             ->willReturn(['id' => 42, 'name' => 'Alice']);

        $service = new UserService($repo);
        $user = $service->getUser(42);

        $this->assertSame('Alice', $user['name']);
    }
}
```

## Setup and teardown

```php
<?php
use PHPUnit\Framework\TestCase;

class DatabaseTest extends TestCase
{
    private \PDO $pdo;

    protected function setUp(): void
    {
        $this->pdo = new \PDO('sqlite::memory:');
        $this->pdo->exec('CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)');
        $this->pdo->exec("INSERT INTO users (name) VALUES ('Alice'), ('Bob')");
    }

    protected function tearDown(): void
    {
        // PDO in-memory is auto-destroyed when $this->pdo is unset
        unset($this->pdo);
    }

    public function testCountUsers(): void
    {
        $count = (int) $this->pdo->query('SELECT COUNT(*) FROM users')->fetchColumn();
        $this->assertSame(2, $count);
    }
}
```

## PHPUnit 13.x Attributes (replaces @-annotations)

```php
<?php
use PHPUnit\Framework\TestCase;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\Attributes\RequiresPhp;
use PHPUnit\Framework\Attributes\TestDox;

class ExampleTest extends TestCase
{
    #[Group('database')]
    #[TestDox('User can be created with valid data')]
    public function testCreateUser(): void
    {
        $this->assertTrue(true);
    }

    #[DataProvider('provideNumbers')]
    public function testNumber(int $n): void
    {
        $this->assertGreaterThan(0, $n);
    }

    public static function provideNumbers(): array
    {
        return [[1], [2], [3]];
    }

    #[RequiresPhp('>=8.5')]
    public function testRequiresPhp85(): void
    {
        // skipped on PHP < 8.5
        $this->assertTrue(true);
    }
}
```

## Running tests

```bash
# All tests in tests/ directory
php vendor/bin/phpunit tests

# Specific test file
php vendor/bin/phpunit tests/CalculatorTest.php

# Specific test method
php vendor/bin/phpunit --filter testAdd tests/CalculatorTest.php

# With text coverage
php vendor/bin/phpunit --coverage-text tests

# With HTML coverage report (to coverage-html/)
php vendor/bin/phpunit --coverage-html coverage-html tests

# With JUnit XML output (for CI)
php vendor/bin/phpunit --log-junit junit.xml tests

# Stop on first failure
php vendor/bin/phpunit --stop-on-failure tests

# Only run tests in 'database' group
php vendor/bin/phpunit --group database tests
```

## Common assertions

```php
// Equality (strict — uses ===)
$this->assertSame($expected, $actual);
$this->assertEquals($expected, $actual);  // loose ==

// Type
$this->assertIsInt($value);
$this->assertIsString($value);
$this->assertIsArray($value);
$this->assertIsBool($value);
$this->assertInstanceOf(SomeClass::class, $object);

// Boolean
$this->assertTrue($condition);
$this->assertFalse($condition);
$this->assertNull($value);
$this->assertNotNull($value);

// Arrays
$this->assertCount(3, $array);
$this->assertContains('item', $array);
$this->assertContainsOnly('int', $array);
$this->assertArrayHasKey('key', $array);

// Strings
$this->assertStringStartsWith('prefix', $string);
$this->assertStringEndsWith('suffix', $string);
$this->assertStringContainsString('substring', $string);
$this->assertMatchesRegularExpression('/^foo.*bar$/', $string);

// Exceptions (alternative to expectException())
$this->expectException(\Exception::class);
$this->expectExceptionMessage('specific message');
$this->expectExceptionCode(123);
```
