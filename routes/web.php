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
