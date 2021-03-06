.. image:: https://img.shields.io/pypi/v/snails.svg?style=flat-square
    :target: https://pypi.python.org/pypi/snails

Sometimes you want to write a dumb email handler.

Good for: low volume, minimal parsing, interacting with legacy email-based systems

Bad for: high volume, production use, 100% RFC compliance


Requires Python 3.7+

::

    pip install snails

=======
 Usage
=======

.. code-block:: python

    import snails


    def handle(msg: snails.Message) -> None:
        print(f"To: {msg['to']}")
        print(f"From: {msg['from']}")
        print("Subject: {msg['subject']}")
        for p in msg.get_payload():
            print(p.get_payload(decode=True))

    # run and block until ctrl + c
    snails.serve(handle, "0.0.0.0", 8025)

.. code-block:: python

    # or, call start/stop yourself
    mailbox = snails.Mailbox(handle, "0.0.0.0", 8025)
    mailbox.start()

============
 Enable TLS
============

.. code-block:: python

    import ssl
    import snails


    def handle(msg: bytes) -> None:
        ...  # TODO


    ssl_context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
    ssl_context.load_cert_chain("cert.pem", "key.pem")

    mailbox = snails.Mailbox(handle, "::", 25, ssl_context=ssl_context)

=================
 Message Parsing
=================

When a new request arrives, ``snails`` will pass the envelope to a parser function.  You can either provide this
parser yourself, or let snails infer the parser based on your handler's type annotations.

Snails provides parsers for the following types:

* ``bytes``
* ``aiosmtpd.smtp.Envelope`` (aliased to ``snails.Envelope``)
* ``email.message.Message`` (aliased to ``snails.Message``)


Most of the time it's enough to use an annotation:

.. code-block:: python

    def handle(x: bytes):
        with open("out.log", "wb") as f:
            f.write(x)

    def handle(x: snails.Envelope):
        with open("out.log", "wb") as f:
            f.write(x.content)

    def handle(x: snails.Message):
        with open("out.log", "wb") as f:
            f.write(x.as_bytes())


You can also define your own parser:

.. code-block:: python

    def parse(e: snails.Envelope) -> dict:
        as_str = e.content.decode()
        return {}  # TODO your parsing


    def handle(x: dict):
        ...  # TODO use the dict parsed above


    mailbox = snails.Mailbox(handle, "::", 25, parser=parse)

===============
 Async Mailbox
===============

Your handler and parser can both be async functions; by default ``snails`` wraps all synchronous functions.

.. code-block:: python

    import snails

    async def parse(e: snails.Envelope) -> dict:
        as_str = e.content.decode()
        return {}  # TODO your parsing


    async def handle(x: dict):
        res = await some_db_call(...)


    mailbox = snails.Mailbox(handle, "::", 25, parser=parse)

=======
 Other
=======

* You can return a string from your handler such as ``"250 OK"`` or the built-in ``snails.SMTP_250``.
* Instead of ``snails.serve`` use ``Mailbox.start`` and ``Mailbox.stop``
* Call ``snails.serve`` with ``cleanup_at_exit=True`` to ensure ``Mailbox.stop`` is called
  when the interpreter is shutting down (enabled by default)
* Call ``snails.serve`` with ``block=True`` to block execution after calling ``Mailbox.start`` (enabled by default).
  You can stop the server by sending SIGINT or Ctrl + C.
