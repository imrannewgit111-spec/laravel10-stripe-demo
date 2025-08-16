#!/usr/bin/env bash
set -e

# --- Prereqs check ---
command -v composer >/dev/null 2>&1 || { echo "Composer not found. Install from https://getcomposer.org/"; exit 1; }
command -v php >/dev/null 2>&1 || { echo "PHP not found. Install PHP 8.1+."; exit 1; }

APP_DIR="laravel10-stripe-demo"

# --- Create Laravel 10 project ---
composer create-project laravel/laravel "$APP_DIR" "10.*"
cd "$APP_DIR"

# --- Install Stripe SDK ---
composer require stripe/stripe-php

# --- Make model + migration + seeder ---
php artisan make:model Product -m
php artisan make:seeder ProductSeeder

# Overwrite migration for products
MIG=$(ls database/migrations/*create_products_table*.php | head -n1)
cat > "$MIG" <<'PHP'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('description')->nullable();
            $table->decimal('price_inr', 10, 2)->default(0);
            $table->timestamps();
        });
    }
    public function down(): void {
        Schema::dropIfExists('products');
    }
};
PHP

# Seeder content
cat > database/seeders/ProductSeeder.php <<'PHP'
<?php
namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Product;

class ProductSeeder extends Seeder
{
    public function run(): void
    {
        Product::truncate();
        Product::create(['title'=>'Basic Plan','description'=>'One-time demo item','price_inr'=>199]);
        Product::create(['title'=>'Pro Plan','description'=>'Advanced demo item','price_inr'=>299]);
        Product::create(['title'=>'Platinum Plan','description'=>'Full demo item','price_inr'=>499]);
    }
}
PHP

# Update DatabaseSeeder to call ProductSeeder
php -r "
\$p='database/seeders/DatabaseSeeder.php';
\$s=file_get_contents(\$p);
if (strpos(\$s, 'ProductSeeder::class')===false) {
  \$s=str_replace('public function run()','public function run()',\$s);
  \$s=preg_replace('/class DatabaseSeeder extends Seeder\\s*\\{\\s*public function run\\(\\)\\s*\\{\\s*/s','class DatabaseSeeder extends Seeder { public function run(): void { $this->call([\\n            \\Database\\\\Seeders\\\\ProductSeeder::class,\\n        ]);\\n',\$s,1);
  file_put_contents(\$p,\$s);
}
"

# --- Controllers ---
php artisan make:controller ProductController
php artisan make:controller CheckoutController

# ProductController
cat > app/Http/Controllers/ProductController.php <<'PHP'
<?php
namespace App\Http\Controllers;

use App\Models\Product;

class ProductController extends Controller
{
    public function index()
    {
        $products = Product::latest()->paginate(12);
        return view('products.index', compact('products'));
    }
    public function show(Product $product)
    {
        return view('products.show', compact('product'));
    }
}
PHP

# CheckoutController
cat > app/Http/Controllers/CheckoutController.php <<'PHP'
<?php
namespace App\Http\Controllers;

use App\Models\Product;
use Illuminate\Http\Request;
use Stripe\Stripe;
use Stripe\Checkout\Session as CheckoutSession;

class CheckoutController extends Controller
{
    public function create(Product $product)
    {
        return view('payment.checkout', compact('product'));
    }

    public function start(Request $request, Product $product)
    {
        Stripe::setApiKey(config('services.stripe.secret'));
        $amountInPaise = (int) round($product->price_inr * 100);

        $session = CheckoutSession::create([
            'payment_method_types' => ['card'],
            'line_items' => [[
                'price_data' => [
                    'currency' => 'inr',
                    'product_data' => ['name' => $product->title],
                    'unit_amount' => $amountInPaise,
                ],
                'quantity' => 1,
            ]],
            'mode' => 'payment',
            'success_url' => url('/payment/success'),
            'cancel_url' => url('/payment/cancel'),
        ]);

        return redirect($session->url, 303);
    }
}
PHP

# --- Views ---
mkdir -p resources/views/{layouts,products,payment}

cat > resources/views/layouts/app.blade.php <<'BLADE'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Laravel10 Stripe Demo</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
<nav class="navbar navbar-expand-lg navbar-dark bg-dark">
  <div class="container-fluid">
    <a class="navbar-brand" href="{{ url('/') }}">L10 Stripe</a>
    <div>
      <a class="btn btn-primary btn-sm" href="{{ route('products.index') }}">Products</a>
    </div>
  </div>
</nav>
<main class="py-4">
  @yield('content')
</main>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
BLADE

cat > resources/views/products/index.blade.php <<'BLADE'
@extends('layouts.app')
@section('content')
<div class="container">
  <h1 class="mb-3">Products</h1>
  <div class="row">
    @foreach($products as $product)
      <div class="col-md-4">
        <div class="card mb-3">
          <div class="card-body">
            <h5 class="card-title">{{ $product->title }}</h5>
            <p class="card-text">{{ $product->description }}</p>
            <p class="fw-bold">₹{{ number_format($product->price_inr, 2) }}</p>
            <a href="{{ route('products.show', $product) }}" class="btn btn-outline-primary btn-sm">View</a>
            <a href="{{ route('checkout.create', $product) }}" class="btn btn-primary btn-sm">Buy</a>
          </div>
        </div>
      </div>
    @endforeach
  </div>
  {{ $products->links() }}
</div>
@endsection
BLADE

cat > resources/views/products/show.blade.php <<'BLADE'
@extends('layouts.app')
@section('content')
<div class="container">
  <h1>{{ $product->title }}</h1>
  <p>{{ $product->description }}</p>
  <p class="fw-bold">₹{{ number_format($product->price_inr, 2) }}</p>
  <a href="{{ route('checkout.create', $product) }}" class="btn btn-primary">Proceed to Checkout</a>
  <a href="{{ route('products.index') }}" class="btn btn-link">Back</a>
</div>
@endsection
BLADE

cat > resources/views/payment/checkout.blade.php <<'BLADE'
@extends('layouts.app')
@section('content')
<div class="container">
  <h1 class="mb-3">Checkout — {{ $product->title }}</h1>
  <p>Amount: <strong>₹{{ number_format($product->price_inr, 2) }}</strong></p>
  <form method="POST" action="{{ route('checkout.start', $product) }}">
    @csrf
    <button class="btn btn-primary">Pay with Stripe</button>
  </form>
  <p class="mt-3 text-muted">Test card: 4242 4242 4242 4242 (any future expiry, any CVC)</p>
</div>
@endsection
BLADE

cat > resources/views/payment/success.blade.php <<'BLADE'
@extends('layouts.app')
@section('content')
<div class="container">
  <div class="alert alert-success">Payment successful! 🎉 (Test mode)</div>
  <a class="btn btn-success" href="{{ route('products.index') }}">Continue</a>
</div>
@endsection
BLADE

cat > resources/views/payment/cancel.blade.php <<'BLADE'
@extends('layouts.app')
@section('content')
<div class="container">
  <div class="alert alert-warning">Payment cancelled. Try again.</div>
  <a class="btn btn-primary" href="{{ route('products.index') }}">Back</a>
</div>
@endsection
BLADE

# --- Routes ---
# Replace default route file with our definitions
cat > routes/web.php <<'PHP'
<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\CheckoutController;

Route::get('/', fn() => redirect()->route('products.index'));
Route::get('/products', [ProductController::class, 'index'])->name('products.index');
Route::get('/products/{product}', [ProductController::class, 'show'])->name('products.show');

Route::get('/checkout/{product}', [CheckoutController::class, 'create'])->name('checkout.create');
Route::post('/checkout/{product}', [CheckoutController::class, 'start'])->name('checkout.start');
Route::view('/payment/success', 'payment.success')->name('payment.success');
Route::view('/payment/cancel', 'payment.cancel')->name('payment.cancel');
PHP

# --- services.php snippet (append if not present) ---
php -r "
\$p='config/services.php';
\$s=file_get_contents(\$p);
if (strpos(\$s, \"'stripe' => [\")===false) {
  \$s=str_replace('return [','return [\\n    \\'' . 'stripe' . '\\' => [\\n        \\'' . 'key' . '\\' => env(\\'' . 'STRIPE_KEY' . '\\'),\\n        \\'' . 'secret' . '\\' => env(\\'' . 'STRIPE_SECRET' . '\\'),\\n    ],\\n',\$s);
  file_put_contents(\$p,\$s);
}
"

echo
echo "==============================================="
echo " DONE! Next steps:"
echo " 1) Edit .env and set DB + STRIPE_KEY/STRIPE_SECRET"
echo " 2) php artisan migrate --seed"
echo " 3) php artisan serve"
echo " Open http://127.0.0.1:8000/products"
echo "==============================================="
