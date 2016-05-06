--cancel the process
SELECT pg_cancel_backend(pid);
SELECT pg_terminate_backend(pid);