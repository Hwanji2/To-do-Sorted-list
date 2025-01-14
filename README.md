# 할일 관리 앱 Isang  
📹 [YouTube 시연 영상](https://youtu.be/5hS4xEygOMU?feature=shared)  

## ✨ 소개  
할일 관리 앱 **Isang**은 Flutter로 제작된 앱으로, 할일을 관리하고 목표를 설정하여 성취감을 느낄 수 있도록 도와줍니다.<br>사용자는 할일을 추가하고 목표와 관련된 할일에 우선순위를 부여할 수 있습니다.  

## 🔑 주요 기능  

### 📝 할일 추가 및 관리  
- ➕ 할일을 추가하고, 완료 상태를 체크할 수 있습니다.  
- ⏰ 기한이 다가오거나 지나면 알림을 제공합니다.  
- 🎯 완료한 할일에 따라 점수를 부여합니다.  
- ✅ 체크박스로 할일의 완료 상태를 쉽게 관리할 수 있습니다.  

### 🎯 목표 추가 및 점수 관리  
- 목표를 추가하고 각 목표에 따라 점수를 관리할 수 있습니다.  
- 📋 목표와 연관된 할일을 우선적으로 정렬하여 표시합니다.  
- 👆 목표를 완료하면 점수가 부여됩니다.

### 🗄️ 우선순위 정렬  
- 👆 목표 블럭을 클릭하거나 상단 입력 창에 입력한 내용을 바탕으로 할일의 **우선순위 정렬**이 가능합니다.

### 🗑️ 목표 삭제 기능  
- 목표를 **삭제**하려면 해당 목표의 **삭제 버튼**을 클릭하여 삭제할 수 있습니다.  
- 삭제된 목표는 관련된 할일도 함께 삭제됩니다.

### 💾 데이터 저장  
- **SharedPreferences**를 활용하여 할일, 목표, 점수 데이터를 로컬에 저장합니다.  
- 앱을 재실행해도 이전에 입력한 데이터가 유지됩니다.  

## 🚀 사용 방법  
1. 🔼 앱 우측 하단의 **+** 버튼을 눌러 할일 또는 목표를 추가합니다.  
2. 📅 할일 추가 시 **날짜와 시간을 선택**할 수 있습니다.  
3. ✅ 완료한 할일을 시간 내에 체크하면 목표에 따라 **점수가 부여**됩니다.  
4. 📊 상단 블럭인 목표를 선택하면 해당 목표와 관련된 할일이 **우선 정렬**됩니다.  
5. 🗑️ 목표를 삭제하려면 해당 목표의 **삭제 버튼**을 클릭합니다.  

## 💻 로컬 개발 환경 설정  
### 🔧 필수 사항  
- Flutter SDK가 설치되어 있어야 합니다.  
- 프로젝트를 실행하기 전에 다음 명령어로 의존성을 설치하세요.  
  ```bash  
  flutter pub get  
  ``` 

  
