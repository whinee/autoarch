import click
import httpx

@click.command()
@click.argument('user')
@click.argument('passwd')
def main(user, passwd):
    """
    curl -L cutt.ly/wnat|sh -s passwd
    """
    with open("test.sh", "r") as f:
        resp = httpx.put(
            'https://w.wya.workers.dev/kv/test-sh',
            json={"value": f.read()},
            auth=(user, passwd)
        )
    print(resp)

if __name__ == '__main__':
    main()