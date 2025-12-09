# Django App

#### generation a new secret key
```python
from django.core.management.utils import get_random_secret_key
print(get_random_secret_key())
```

#### install dependencies
```shell
uv add <python_lib>

# or

uv add --dev <python_lib>
```
