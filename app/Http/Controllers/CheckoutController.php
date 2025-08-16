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
