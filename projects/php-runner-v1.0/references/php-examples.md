# PHP Modern Examples Reference

Quick-reference patterns for PHP 8.1+ features. Load this when writing or reviewing PHP code.

## Table of Contents
- [Enums](#enums)
- [Readonly Classes & Properties](#readonly-classes--properties)
- [Fibers](#fibers)
- [Match Expression](#match-expression)
- [Named Arguments](#named-arguments)
- [Constructor Property Promotion](#constructor-property-promotion)
- [Nullsafe Operator](#nullsafe-operator)
- [Attributes](#attributes)
- [PDO + SQLite](#pdo--sqlite)
- [Error Handling](#error-handling)
- [Composer Quick Start](#composer-quick-start)

---

## Enums

```php
<?php
enum Status: string
{
    case PENDING = 'pending';
    case ACTIVE = 'active';
    case ARCHIVED = 'archived';

    public function label(): string
    {
        return match($this) {
            self::PENDING => 'Awaiting approval',
            self::ACTIVE => 'Currently active',
            self::ARCHIVED => 'Moved to archive',
        };
    }

    public function isActive(): bool
    {
        return $this === self::ACTIVE;
    }
}

// Usage
$status = Status::from('active');
echo $status->label(); // "Currently active"
echo $status->value;   // "active"
```

## Readonly Classes & Properties

```php
<?php
// PHP 8.2+: readonly class — all properties are readonly automatically
readonly class UserDTO
{
    public function __construct(
        public string $name,
        public string $email,
        public ?DateTimeImmutable $createdAt = null,
    ) {}
}

// PHP 8.1+: readonly properties individually
class Product
{
    public function __construct(
        public readonly string $sku,
        public readonly float $price,
        public string $description, // mutable
    ) {}
}
```

## Fibers

```php
<?php
// Lightweight concurrency for cooperative multitasking
$fiber = new Fiber(function (): void {
    $value = Fiber::suspend('fiber start');
    echo "Fiber received: $value\n";
    Fiber::suspend('midpoint');
    echo "Fiber ending\n";
});

$state = $fiber->start();
echo "Main got: $state\n";

$state = $fiber->resume('hello from main');
echo "Main got: $state\n";

$fiber->resume('continue');
```

## Match Expression

```php
<?php
// Replace verbose switch/if-else with match
$httpCode = 404;
$message = match ($httpCode) {
    200, 204 => 'Success',
    301, 302 => 'Redirect',
    400 => 'Bad Request',
    401 => 'Unauthorized',
    403 => 'Forbidden',
    404 => 'Not Found',
    500 => 'Server Error',
    default => 'Unknown status',
};

// Match with strict types ($age must be defined first)
$age = 25;
$result = match (true) {
    $age < 13 => 'child',
    $age < 20 => 'teenager',
    $age < 65 => 'adult',
    default   => 'senior',
};
echo $result; // adult
```

## Named Arguments

```php
<?php
function createUser(
    string $name,
    string $email,
    bool $isAdmin = false,
    ?string $avatar = null,
    array $roles = [],
): User {
    // ...
}

// Call with named arguments for clarity
$user = createUser(
    name: 'Ana',
    email: 'ana@example.com',
    roles: ['editor', 'reviewer'],
);
```

## Constructor Property Promotion

```php
<?php
// Before PHP 8.0: verbose
class OrderLegacy
{
    private string $id;
    private float $total;

    public function __construct(string $id, float $total)
    {
        $this->id = $id;
        $this->total = $total;
    }
}

// PHP 8.0+: promoted constructor properties
class Order
{
    public function __construct(
        private string $id,
        private float $total,
        private ?DateTimeImmutable $placedAt = null,
    ) {}

    public function id(): string { return $this->id; }
    public function total(): float { return $this->total; }
}
```

## Nullsafe Operator

```php
<?php
// PHP 8.0+: nullsafe operator ?->
$country = $user?->getAddress()?->getCountry()?->getName() ?? 'Unknown';

// Equivalent without nullsafe (verbose)
$country = 'Unknown';
if ($user !== null) {
    $address = $user->getAddress();
    if ($address !== null) {
        $countryObj = $address->getCountry();
        if ($countryObj !== null) {
            $country = $countryObj->getName();
        }
    }
}
```

## Attributes

```php
<?php
// PHP 8.0+: native attributes (replaces docblock annotations)
#[Attribute(Attribute::TARGET_METHOD)]
class Route
{
    public function __construct(
        public string $path,
        public string $method = 'GET',
    ) {}
}

class UserController
{
    #[Route('/users', method: 'GET')]
    public function index(): array { /* ... */ }

    #[Route('/users', method: 'POST')]
    public function store(): array { /* ... */ }
}

// Read attributes via reflection
$ref = new ReflectionClass(UserController::class);
foreach ($ref->getMethods() as $method) {
    foreach ($method->getAttributes(Route::class) as $attr) {
        $route = $attr->newInstance();
        echo "{$route->method} {$route->path} => {$method->getName()}\n";
    }
}
```

## PDO + SQLite

```php
<?php
// In-memory SQLite — no external DB server needed
$pdo = new PDO('sqlite::memory:');
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);

// Create table
$pdo->exec('
    CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
');

// Prepared insert (safe against SQL injection)
$stmt = $pdo->prepare('INSERT INTO users (name, email) VALUES (:name, :email)');
$stmt->execute([':name' => 'Ana', ':email' => 'ana@example.com']);
$stmt->execute([':name' => 'Bob', ':email' => 'bob@example.com']);

// Fetch all
$users = $pdo->query('SELECT * FROM users')->fetchAll();
print_r($users);

// Transaction
$pdo->beginTransaction();
try {
    $pdo->prepare('UPDATE users SET name = ? WHERE id = ?')->execute(['Anna', 1]);
    $pdo->commit();
} catch (PDOException $e) {
    $pdo->rollBack();
    throw $e;
}
```

## Error Handling

```php
<?php
// PHP 8.0+: throw as expression
$value = $_GET['page'] ?? throw new InvalidArgumentException('Page required');

// Custom exception hierarchy
try {
    $result = riskyOperation();
} catch (ValidationException $e) {
    http_response_code(422);
    echo json_encode(['error' => $e->getMessage(), 'field' => $e->getField()]);
} catch (NotFoundException $e) {
    http_response_code(404);
    echo json_encode(['error' => 'Resource not found']);
} catch (Throwable $e) {
    error_log($e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'Internal server error']);
}

// PHP 8.3+: json_validate() — no need to decode just to check
if (!json_validate($payload)) {
    throw new RuntimeException('Invalid JSON payload');
}
```

## Composer Quick Start

```bash
# Initialize a new project
composer init --name=myproject/app --no-interaction

# Add dependencies
composer require vlucas/phpdotenv doctrine/dbal

# Add dev dependencies
composer require --dev phpunit/phpunit phpstan/phpstan

# Autoload config (in composer.json)
# "autoload": {
#     "psr-4": {
#         "App\\\\": "src/"
#     }
# }
composer dump-autoload

# Run scripts
composer run test
composer run phpstan
```
