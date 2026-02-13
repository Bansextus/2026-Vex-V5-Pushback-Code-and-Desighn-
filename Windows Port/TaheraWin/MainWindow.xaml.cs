using System.Diagnostics;
using System.Text;
using System.Windows;

namespace Tahera {
    public partial class MainWindow : Window {
        private const string RepoSettingsPassword = "56Wrenches.782";
        private bool _repoUnlocked = false;

        private readonly Dictionary<string, (string path, int slot)> _projects = new() {
            { "The Tahera Sequence", ("Pros projects/Tahera_Project", 1) },
            { "Auton Planner", ("Pros projects/Auton_Planner_PROS", 2) },
            { "Image Selector", ("Pros projects/Jerkbot_Image_Test", 3) },
            { "Basic Bonkers", ("Pros projects/Basic_Bonkers_PROS", 4) }
        };

        public MainWindow() {
            InitializeComponent();
            RepoPathTextBox.Text = @"C:\Users\Public\GitHub\2026-Vex-V5-Pushback-Code-and-Desighn-";
            ProjectComboBox.ItemsSource = _projects.Keys;
            ProjectComboBox.SelectedIndex = 0;
            ShowSection("Home");
        }

        private string RepoPath => RepoPathTextBox.Text.Trim();

        private async Task<(int code, string output)> RunCommandAsync(string fileName, string args, string? workingDirectory = null) {
            var psi = new ProcessStartInfo(fileName, args) {
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            if (!string.IsNullOrWhiteSpace(workingDirectory)) {
                psi.WorkingDirectory = workingDirectory;
            }

            var sb = new StringBuilder();
            using var p = new Process { StartInfo = psi };
            p.OutputDataReceived += (_, e) => { if (e.Data != null) sb.AppendLine(e.Data); };
            p.ErrorDataReceived += (_, e) => { if (e.Data != null) sb.AppendLine(e.Data); };

            p.Start();
            p.BeginOutputReadLine();
            p.BeginErrorReadLine();
            await p.WaitForExitAsync();
            return (p.ExitCode, sb.ToString());
        }

        private void AppendOutput(string text) {
            OutputTextBox.AppendText(text + Environment.NewLine);
            OutputTextBox.ScrollToEnd();
        }

        private void ShowSection(string tag) {
            HomePanel.Visibility = Visibility.Collapsed;
            BuildPanel.Visibility = Visibility.Collapsed;
            PortPanel.Visibility = Visibility.Collapsed;
            SdPanel.Visibility = Visibility.Collapsed;
            FieldPanel.Visibility = Visibility.Collapsed;
            GitPanel.Visibility = Visibility.Collapsed;

            switch (tag) {
                case "Build": BuildPanel.Visibility = Visibility.Visible; break;
                case "Port": PortPanel.Visibility = Visibility.Visible; break;
                case "Sd": SdPanel.Visibility = Visibility.Visible; break;
                case "Field": FieldPanel.Visibility = Visibility.Visible; break;
                case "Git": GitPanel.Visibility = Visibility.Visible; break;
                default: HomePanel.Visibility = Visibility.Visible; break;
            }
        }

        private void SectionButton_Click(object sender, RoutedEventArgs e) {
            if (sender is FrameworkElement el && el.Tag is string tag) {
                ShowSection(tag);
            }
        }

        private (string name, string path, int slot)? SelectedProject() {
            if (ProjectComboBox.SelectedItem is not string name) return null;
            if (!_projects.TryGetValue(name, out var data)) return null;
            return (name, System.IO.Path.Combine(RepoPath, data.path), data.slot);
        }

        private async void Build_Click(object sender, RoutedEventArgs e) {
            var p = SelectedProject();
            if (p == null) return;
            AppendOutput($"$ pros make ({p.Value.name})");
            var result = await RunCommandAsync("cmd", "/c pros make", p.Value.path);
            AppendOutput(result.output);
        }

        private async void Upload_Click(object sender, RoutedEventArgs e) {
            var p = SelectedProject();
            if (p == null) return;
            AppendOutput($"$ pros upload --slot {p.Value.slot} ({p.Value.name})");
            var result = await RunCommandAsync("cmd", $"/c pros upload --slot {p.Value.slot}", p.Value.path);
            AppendOutput(result.output);
        }

        private async void BuildUpload_Click(object sender, RoutedEventArgs e) {
            var p = SelectedProject();
            if (p == null) return;
            AppendOutput($"$ pros make ({p.Value.name})");
            var build = await RunCommandAsync("cmd", "/c pros make", p.Value.path);
            AppendOutput(build.output);
            if (build.code == 0) {
                AppendOutput($"$ pros upload --slot {p.Value.slot} ({p.Value.name})");
                var upload = await RunCommandAsync("cmd", $"/c pros upload --slot {p.Value.slot}", p.Value.path);
                AppendOutput(upload.output);
            }
        }

        private void UnlockRepoSettings_Click(object sender, RoutedEventArgs e) {
            var entered = RepoSettingsPasswordBox.Password;
            if (entered == RepoSettingsPassword) {
                _repoUnlocked = true;
                GitLockedPanel.Visibility = Visibility.Collapsed;
                GitUnlockedPanel.Visibility = Visibility.Visible;
                AuthErrorText.Text = "";
                RepoSettingsPasswordBox.Password = "";
                AppendOutput("Repository settings unlocked");
            } else {
                AuthErrorText.Text = "Incorrect password";
            }
        }

        private void LockRepoSettings_Click(object sender, RoutedEventArgs e) {
            _repoUnlocked = false;
            GitUnlockedPanel.Visibility = Visibility.Collapsed;
            GitLockedPanel.Visibility = Visibility.Visible;
            AuthErrorText.Text = "";
        }

        private bool EnsureUnlocked() {
            if (_repoUnlocked) return true;
            MessageBox.Show("Repository settings are locked.");
            return false;
        }

        private async void GitCommit_Click(object sender, RoutedEventArgs e) {
            if (!EnsureUnlocked()) return;
            var msg = CommitMessageTextBox.Text.Trim();
            if (msg.Length == 0) return;
            AppendOutput("$ git add -A");
            await RunCommandAsync("cmd", "/c git add -A", RepoPath);
            AppendOutput("$ git commit");
            var result = await RunCommandAsync("cmd", $"/c git commit -m \"{msg}\"", RepoPath);
            AppendOutput(result.output);
        }

        private async void GitPush_Click(object sender, RoutedEventArgs e) {
            if (!EnsureUnlocked()) return;
            AppendOutput("$ git push");
            var result = await RunCommandAsync("cmd", "/c git push", RepoPath);
            AppendOutput(result.output);
        }

        private async void GitTagPush_Click(object sender, RoutedEventArgs e) {
            if (!EnsureUnlocked()) return;
            var tag = TagTextBox.Text.Trim();
            if (tag.Length == 0) return;
            var msg = TagMessageTextBox.Text.Trim();
            if (msg.Length == 0) msg = tag;
            AppendOutput("$ git tag");
            var tagRes = await RunCommandAsync("cmd", $"/c git tag -a {tag} -m \"{msg}\"", RepoPath);
            AppendOutput(tagRes.output);
            AppendOutput("$ git push --tags");
            var pushRes = await RunCommandAsync("cmd", "/c git push --tags", RepoPath);
            AppendOutput(pushRes.output);
        }

        private async void GitRelease_Click(object sender, RoutedEventArgs e) {
            if (!EnsureUnlocked()) return;
            var tag = TagTextBox.Text.Trim();
            if (tag.Length == 0) return;
            var title = ReleaseTitleTextBox.Text.Trim();
            if (title.Length == 0) title = tag;
            var notes = ReleaseNotesTextBox.Text;
            AppendOutput("$ gh release create");
            var res = await RunCommandAsync("cmd", $"/c gh release create {tag} --title \"{title}\" --notes \"{notes}\"", RepoPath);
            AppendOutput(res.output);
        }
    }
}
