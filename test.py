import click
import httpx

@click.command()
@click.argument('kv')
def main(kv):
    """
    curl -L cutt.ly/whine
    """
    with open("test.sh", "r") as f:
        httpx.post(f'https://{kv}.whi-ne.workers.dev', json={"test-sh": f.read()})

if __name__ == '__main__':
    main()