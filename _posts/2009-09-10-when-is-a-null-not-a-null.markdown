---
author: tom.vaughan
comments: true
date: 2009-09-10 14:48:15+00:00
layout: post
slug: when-is-a-null-not-a-null
title: When is a null not a null?
wordpress_id: 74
categories:
- Best Practice
- Code
---

tl/dr: _Don't have a non-null object's .toString() display "null". It's confusing and not helpful when looking at object states in IDE debuggers._

I recently converted the attribute of our Person POJO that stored a user's email address from a java.lang.String to a javax.mail.InternetAddress.  Call it not enough testing or lack of imagination, but I introduced a Null Pointer Exception in a back-office web flow where a new user is created for our customer service application.  When a new CSR account is created and the email address is left blank, an NPE gets thrown up.  Embarrassing, but easy to fix, right?

Just looking at the stack trace narrows it down immediately:

    
    2009-09-09 16:56:53,636 WARN  [btpool0-1] [REPORT] [WARN] Handler execution resulted in exception
    java.lang.NullPointerException
    	at javax.mail.internet.InternetAddress.parse(InternetAddress.java:609)
    	at javax.mail.internet.InternetAddress.parse(InternetAddress.java:569)
    	at javax.mail.internet.InternetAddress.(InternetAddress.java:105)
    	at poscore.db.InternetAddressUserType.deepCopy(InternetAddressUserType.java:93)
    	at org.hibernate.type.CustomType.deepCopy(CustomType.java:179)
    	at org.hibernate.type.TypeFactory.deepCopy(TypeFactory.java:374)


Ahh...yeah...that custom hibernate type I wrote to translate VARCHARs to InternetAddresses and vice versa.  Ok, what does that deep copy method look like?

{% highlight java %}    
public Object deepCopy(Object value) throws HibernateException {
    if(value == null) {
        return null;
    }
    InternetAddress original = (InternetAddress)value;
    InternetAddress copy = null;
    try {
        copy = new InternetAddress(original.getAddress());
    }
    catch (AddressException ex) {
        throw new HibernateException("Unable to deep copy email address '" + original.getAddress() + "'");
    }
    return copy;
}
{% endhighlight %}

It turns out, the error is right here:

{% highlight java %}
copy = new InternetAddress(original.getAddress());
{% endhighlight %}

You can't pass a null to the InternetAddress constructor.  It was late in the day and I must not have internalized that there's no way _value_ or _original_ could be null, because my first instinct was that the NPE was actually the result of calling ".getAddress()" on a null _original_ object....not that the constructor can't take a null.

While I was on that assumption (that it was the _original_ object that was null), I fired up my debugger and got confused by what appeared to be null-checks failing to check nulls. Check out this screen shot of the NPE about to be thrown after what appears to be 2 null checks failing to prevent the NPE:

![null_internet_address](/img/null_internet_address.png)

The arrows marked (A) and (B) shows what appear to be null objects passing null checks (in the top pane) even though they're being reported as null (in the bottom pane).  The green line (C) shows the code falling through to that line just before it throws up the NPE.

Of course, _value_ and _original_ aren't null at all...it's just that their .toString() methods report them to be null.  Here's the InternetAddress.toString method:

    
    276   public String toString() {
    277       if (encodedPersonal == null && personal != null)
    278           try {
    279	              encodedPersonal = MimeUtility.encodeWord(personal);
    280           } catch (UnsupportedEncodingException ex) { }
    281
    282       if (encodedPersonal != null)
    283           return quotePhrase(encodedPersonal) + " <" + address + ">";
    284       else if (isGroup() || isSimple())
    285           return address;
    286       else
    287           return "<" + address + ">";
    288   }

In my situation, I fell in to the `else if(isGroup() || isSimple())` case, which returns `address`, which is null, so the `.toString()` for the whole InternetAddress object is "null."

I think the toString() method could benefit from another null-check right at line 284, which would mean an InternetAddress object with a null internal `address` String would display as "\<null\>" ...that's a more immediate clue that the object itself isn't null.
