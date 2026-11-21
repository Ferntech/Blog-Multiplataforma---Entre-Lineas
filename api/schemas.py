from datetime import datetime
from typing import Literal
from pydantic import BaseModel, ConfigDict, Field

class LoginRequest(BaseModel):
    email: str = Field(min_length=5, max_length=150)
    password: str = Field(min_length=1, max_length=128)

class UserCreate(BaseModel):
    full_name: str = Field(min_length=2, max_length=100)
    email: str = Field(min_length=5, max_length=150)
    password: str = Field(min_length=8, max_length=128)
    role: Literal["reader", "author", "admin"] = "reader"
    avatar_url: str | None = Field(default=None, max_length=1000)
    bio: str | None = Field(default=None, max_length=500)
    phone: str | None = Field(default=None, max_length=25)
    address_line: str | None = Field(default=None, max_length=255)
    city: str | None = Field(default=None, max_length=100)
    state: str | None = Field(default=None, max_length=100)
    postal_code: str | None = Field(default=None, max_length=20)
    country: str = Field(default="México", max_length=80)

class UserUpdate(BaseModel):
    full_name: str = Field(min_length=2, max_length=100)
    email: str = Field(min_length=5, max_length=150)
    avatar_url: str | None = Field(default=None, max_length=1000)
    bio: str | None = Field(default=None, max_length=500)
    phone: str | None = Field(default=None, max_length=25)
    address_line: str | None = Field(default=None, max_length=255)
    city: str | None = Field(default=None, max_length=100)
    state: str | None = Field(default=None, max_length=100)
    postal_code: str | None = Field(default=None, max_length=20)
    country: str = Field(default="México", max_length=80)

class UserSummary(BaseModel):
    id: int
    full_name: str
    role: str
    avatar_url: str | None = None
    karma: int = 0

    model_config = ConfigDict(from_attributes=True)

class UserResponse(BaseModel):
    id: int
    full_name: str
    email: str
    role: str
    avatar_url: str | None = None
    bio: str | None = None
    phone: str | None = None
    address_line: str | None = None
    city: str | None = None
    state: str | None = None
    postal_code: str | None = None
    country: str
    is_active: bool
    karma: int = 0
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

class AuthorResponse(BaseModel):
    id: int
    name: str
    slug: str
    openlibrary_key: str | None = None
    bio: str | None = None
    photo_url: str | None = None
    birth_year: int | None = None
    nationality: str | None = None

    model_config = ConfigDict(from_attributes=True)

class TagResponse(BaseModel):
    id: int
    name: str
    slug: str

    model_config = ConfigDict(from_attributes=True)

class BookSummary(BaseModel):
    id: int
    title: str
    slug: str
    isbn_13: str
    cover_url: str | None = None
    price: float
    stock: int
    status: str
    authors: list[AuthorResponse] = []

    model_config = ConfigDict(from_attributes=True)

class BookResponse(BaseModel):
    id: int
    title: str
    subtitle: str | None = None
    slug: str
    isbn_10: str | None = None
    isbn_13: str
    publisher: str | None = None
    published_year: int | None = None
    page_count: int | None = None
    language: str
    cover_url: str | None = None
    synopsis: str | None = None
    price: float
    stock: int
    status: str
    authors: list[AuthorResponse] = []
    tags: list[TagResponse] = []
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

class BlogPostResponse(BaseModel):
    id: int
    author_id: int | None = None
    book_id: int
    title: str
    slug: str
    excerpt: str | None = None
    content: str
    rating: int
    status: str
    published_at: datetime | None = None
    created_at: datetime
    updated_at: datetime
    author: UserSummary | None = None
    book: BookSummary
    tags: list[TagResponse] = []
    vote_score: int = 0
    user_vote: int = 0
    comments_count: int = 0

    model_config = ConfigDict(from_attributes=True)

class VoteRequest(BaseModel):
    user_id: int
    vote_value: Literal[-1, 0, 1]

class VoteResponse(BaseModel):
    post_id: int
    vote_score: int
    user_vote: int
    author_karma: int = 0

class CommentMediaCreate(BaseModel):
    media_type: Literal["gif", "sticker"] = "gif"
    giphy_id: str = Field(min_length=1, max_length=64)
    media_url: str = Field(min_length=5, max_length=1000)
    preview_url: str | None = Field(default=None, max_length=1000)
    width: int | None = None
    height: int | None = None
    alt_text: str | None = Field(default=None, max_length=200)

class CommentMediaResponse(BaseModel):
    id: int
    provider: str
    media_type: str
    giphy_id: str
    media_url: str
    preview_url: str | None = None
    width: int | None = None
    height: int | None = None
    alt_text: str | None = None

    model_config = ConfigDict(from_attributes=True)

class CommentCreate(BaseModel):
    user_id: int
    content: str = Field(default="", max_length=3000)
    media: CommentMediaCreate | None = None

class CommentResponse(BaseModel):
    id: int
    post_id: int
    user_id: int
    content: str
    status: str
    created_at: datetime
    user: UserSummary
    media: list[CommentMediaResponse] = []

    model_config = ConfigDict(from_attributes=True)

class GiphyItemResponse(BaseModel):
    giphy_id: str
    media_type: Literal["gif", "sticker"]
    media_url: str
    preview_url: str
    width: int | None = None
    height: int | None = None
    alt_text: str

class PrivateMessageCreate(BaseModel):
    sender_id: int
    recipient_id: int
    content: str = Field(min_length=1, max_length=3000)

class PrivateMessageResponse(BaseModel):
    id: int
    sender_id: int
    recipient_id: int
    content: str
    sent_at: datetime
    read_at: datetime | None = None

    model_config = ConfigDict(from_attributes=True)

class ConversationSummary(BaseModel):
    partner_id: int
    partner_name: str
    partner_role: str
    partner_avatar_url: str | None = None
    last_message: str
    last_sent_at: datetime
    last_sender_id: int
    unread_count: int = 0

class CartItemAdd(BaseModel):
    book_id: int
    quantity: int = Field(default=1, ge=1)

class CartItemUpdate(BaseModel):
    quantity: int = Field(ge=1)

class CartItemResponse(BaseModel):
    id: int
    book_id: int
    quantity: int
    line_total: float
    book: BookSummary

    model_config = ConfigDict(from_attributes=True)

class ShoppingCartResponse(BaseModel):
    id: int
    user_id: int
    status: str
    items: list[CartItemResponse] = []
    subtotal: float
    estimated_shipping: float
    estimated_total: float
    currency: str = "MXN"

class PayPalCheckoutRequest(BaseModel):
    payer_email: str | None = Field(default=None, max_length=150)
    shipping_recipient_name: str | None = Field(default=None, max_length=120)
    shipping_phone: str | None = Field(default=None, max_length=25)
    shipping_address_line: str | None = Field(default=None, max_length=255)
    shipping_city: str | None = Field(default=None, max_length=100)
    shipping_state: str | None = Field(default=None, max_length=100)
    shipping_postal_code: str | None = Field(default=None, max_length=20)
    shipping_country: str = Field(default="México", max_length=80)
    shipping_notes: str | None = Field(default=None, max_length=300)
    
class PayPalOrderCreateResponse(BaseModel):
    paypal_order_id: str
    approve_url: str
    subtotal: float
    shipping_cost: float
    total_amount: float
    currency: str = "MXN"

class PayPalCaptureRequest(PayPalCheckoutRequest):
    paypal_order_id: str = Field(min_length=5, max_length=64)

class OrderItemResponse(BaseModel):
    id: int
    book_id: int | None = None
    book_title_snapshot: str
    book_isbn_snapshot: str
    unit_price: float
    quantity: int
    line_total: float

    model_config = ConfigDict(from_attributes=True)

class PaymentResponse(BaseModel):
    id: int
    provider: str
    paypal_order_id: str
    paypal_capture_id: str | None = None
    payer_email: str | None = None
    amount: float
    currency: str
    status: str
    paid_at: datetime | None = None

    model_config = ConfigDict(from_attributes=True)

class InvoiceResponse(BaseModel):
    id: int
    invoice_number: str
    customer_name: str
    customer_email: str
    billing_address: str
    subtotal: float
    shipping_cost: float
    total_amount: float
    currency: str
    pdf_storage_path: str
    issued_at: datetime

    model_config = ConfigDict(from_attributes=True)

class OrderResponse(BaseModel):
    id: int
    order_reference: str
    user_id: int
    status: str
    subtotal: float
    shipping_cost: float
    total_amount: float
    currency: str
    shipping_recipient_name: str
    shipping_phone: str
    shipping_address_line: str
    shipping_city: str
    shipping_state: str
    shipping_postal_code: str
    shipping_country: str
    shipping_notes: str | None = None
    tracking_number: str | None = None
    shipped_at: datetime | None = None
    delivered_at: datetime | None = None
    created_at: datetime
    items: list[OrderItemResponse] = []
    payments: list[PaymentResponse] = []
    invoice: InvoiceResponse | None = None

    model_config = ConfigDict(from_attributes=True)