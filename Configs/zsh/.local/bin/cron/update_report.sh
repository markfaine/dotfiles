echo "--- OFFLINE UPDATE REPORT ---"
echo "Date: $(date)"
echo ""
echo "1. INSTALLATION ERRORS (Systemd):"
sudo journalctl -u pacman-offline -b 0 --no-hostname | grep -iE "error|failed|conflict" || echo "No critical errors found."
echo ""
echo "2. PENDING CONFIG CHANGES (.pacnew files):"
# .pacnew files indicate where you might need manual configuration merges
sudo find /etc -name "*.pacnew"
echo ""
echo "3. RECENTLY UPGRADED PACKAGES:"
sudo grep "\[ALPM\] upgraded" /var/log/pacman.log | tail -n 20
