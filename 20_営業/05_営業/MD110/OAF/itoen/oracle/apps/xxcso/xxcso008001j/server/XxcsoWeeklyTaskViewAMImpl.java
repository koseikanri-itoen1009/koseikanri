/*============================================================================
* ファイル名 : XxcsoWeeklyTaskViewImpl
* 概要説明   : 週次活動状況照会アプリケーション・モジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-06 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.server;

import com.sun.java.util.collections.List;
import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.Map;
import com.sun.java.util.collections.HashMap;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso008001j.util.XxcsoWeeklyTaskViewConstants;
import java.sql.SQLException;
import java.io.UnsupportedEncodingException;
import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.domain.BlobDomain;
import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleResultSet;

/*******************************************************************************
 * 週次活動状況照会画面のアプリケーション・モジュールクラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoWeeklyTaskViewAMImpl extends OAApplicationModuleImpl 
{

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoWeeklyTaskViewAMImpl()
  {
  }

  /*****************************************************************************
   * 出力メッセージ
   *****************************************************************************
   */
  private OAException mMessage = null;

  /*****************************************************************************
   * 初期化処理
   *****************************************************************************
   */
  public void initDetails()
  {

    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // スケジュール指定リージョンのインスタンス
    XxcsoTaskAppSearchVOImpl taskAppSchVo = getXxcsoTaskAppSearchVO1();
    if ( taskAppSchVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoTaskAppSearchVOImpl");
    }

    if ( ! taskAppSchVo.isPreparedForExecution() )
    {
      // 初期化処理実行
      taskAppSchVo.executeQuery();

      // ****************************************
      // *****属性設定用VOの初期化***************
      // ****************************************
      // 担当者選択リージョンの属性用VO
      this.initEmpSelRender();

      // スケジュールリージョンの属性用VO
      this.initTaskRender();

      // ****************************************
      // *****属性設定用VOの設定*****************
      // ****************************************
      // 担当者選択リージョンの属性設定
      this.setEmpSelItemAttribute(false);

      // スケジュールリージョンの属性設定
      this.setTaskItemAttribute(0);

    XxcsoUtils.debug(txt, "[END]");

    }
  }

  /*****************************************************************************
   * 初期化処理（表示ボタン）
   *****************************************************************************
   */
  public void initAfterHandleShowButton(
    String  txnKey1
  )
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    // スケジュール指定リージョンのインスタンス
    XxcsoTaskAppSearchVOImpl taskAppSchVo = getXxcsoTaskAppSearchVO1();
    if ( taskAppSchVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoTaskAppSearchVOImpl");
    }

    // 担当者選択リージョンのインスタンス
    XxcsoEmpSelSummaryVOImpl empSelVo = getXxcsoEmpSelSummaryVO1();
    if ( empSelVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoEmpSelSummaryVOImpl");
    }

    // 拠点検索VOインスタンス
    XxcsoBaseSearchVOImpl baseSchVo = getXxcsoBaseSearchVO1();
    if ( baseSchVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoBaseSearchVOImpl");
    }
    
    if ( ! taskAppSchVo.isPreparedForExecution() )
    {
      // 初期化処理実行
      taskAppSchVo.executeQuery();

      // ****************************************
      // *****属性設定用VOの初期化***************
      // ****************************************
      // 担当者選択リージョンの属性用VO
      this.initEmpSelRender();

      // スケジュールリージョンの属性用VO
      this.initTaskRender();

      // ****************************************
      // *****属性設定用VOの設定*****************
      // ****************************************
      // 担当者選択リージョンの属性設定
      this.setEmpSelItemAttribute(false);

      // スケジュールリージョンの属性設定
      this.setTaskItemAttribute(0);

      // トランザクションキーより値を抽出
      String[] values = txnKey1.split("\\|");

      for ( int i = 0; i < values.length; i++ )
      {
        XxcsoUtils.debug(txn, "transaction value[" + i + "]" + values[i]);
      }
      
      Date dateSch = new Date(values[0]);
      String baseCodeSch = values[1];

      baseSchVo.initQuery(baseCodeSch);
      XxcsoBaseSearchVORowImpl baseSchRow
        = (XxcsoBaseSearchVORowImpl)baseSchVo.first();
      String baseNameSch = baseSchRow.getBaseName();

      // 日付・部署を設定
      XxcsoTaskAppSearchVORowImpl taskAppSchRow
        = (XxcsoTaskAppSearchVORowImpl)taskAppSchVo.first();
      taskAppSchRow.setDateSch(dateSch);
      taskAppSchRow.setBaseCode(baseCodeSch);
      taskAppSchRow.setBaseName(baseNameSch);

      // 進むボタン押下時処理を実行
      handleForwardButton();

      // 担当者選択リージョンのチェックボックスを設定
      XxcsoEmpSelSummaryVORowImpl empSelRow
        = (XxcsoEmpSelSummaryVORowImpl)empSelVo.first();

      while( empSelRow != null )
      {
        String userId = empSelRow.getUserId().stringValue();
        
        for ( int i = 2; i < values.length; i++ )
        {
          if ( userId.equals(values[i]) )
          {
            empSelRow.setSelectFlg("Y");
            break;
          }
        }
        
        empSelRow = (XxcsoEmpSelSummaryVORowImpl)empSelVo.next();
      }

      // 選択されたユーザーのタスク表示
      // 選択値格納用List(最大10件のため10で初期化)
      List chkdList = new ArrayList(10);

      empSelRow = (XxcsoEmpSelSummaryVORowImpl)empSelVo.first();
      while ( empSelRow != null )
      {
        // 選択CheckBox=ONのオブジェクトを抽出
        if( "Y".equals(empSelRow.getSelectFlg()) )
        {
          // 行情報をmapに格納し、情報抽出用listへ
          Map lineMap = new HashMap(2);
          lineMap.put(
            XxcsoWeeklyTaskViewConstants.RESOURCE_ID
            ,empSelRow.getResourceId()
          );
          lineMap.put(
            XxcsoWeeklyTaskViewConstants.EMP_NAME
            ,empSelRow.getFullName()
          );

          chkdList.add(lineMap);
        }
        empSelRow = (XxcsoEmpSelSummaryVORowImpl)empSelVo.next();
      }

      // スケジュールリージョン表示
      this.createTaskInfo(dateSch, chkdList);
      // スケジュールリージョンの属性設定を行う
      this.setTaskItemAttribute(chkdList.size());

    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * 進むボタン押下時処理
   *****************************************************************************
   */
  public void handleForwardButton()
  {

    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // スケジュール指定リージョンのインスタンス
    XxcsoTaskAppSearchVOImpl taskAppSchVo = getXxcsoTaskAppSearchVO1();
    if ( taskAppSchVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoTaskAppSearchVOImpl");
    }

    // スケジュール指定リージョン行インスタンス
    XxcsoTaskAppSearchVORowImpl taskAppSchVoRow =
      (XxcsoTaskAppSearchVORowImpl) taskAppSchVo.first();
    if ( taskAppSchVoRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoTaskAppSearchVORowImpl");
    }

    // 部署の入力チェックをし、検索対象の拠点コードを取得
    String baseCodeSch = this.chkBaseName(taskAppSchVoRow);

    // 担当者選択リージョンのインスタンス
    XxcsoEmpSelSummaryVOImpl empSelVo = getXxcsoEmpSelSummaryVO1();
    if ( empSelVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoEmpSelSummaryVOImpl");
    }
    // 担当者選択リージョンQuery実行
    empSelVo.initQuery(baseCodeSch);

    // 件数チェック(firstでnullチェック)
    XxcsoEmpSelSummaryVORowImpl empSelVoRow =
      (XxcsoEmpSelSummaryVORowImpl) empSelVo.first();
    if ( empSelVoRow != null )
    {
      // 1件以上ならば表示ボタン表示
      this.setEmpSelItemAttribute(true);
    }
    else
    {
      // 上記以外は非表示
      this.setEmpSelItemAttribute(false);
    }

    // スケジュール表示リージョン属性設定(進むボタン押下で初期化)
    this.setTaskItemAttribute(0);

    XxcsoUtils.debug(txt, "[END]");

  }

  /*****************************************************************************
   * CSV作成ボタン押下時処理
   *****************************************************************************
   */
  public void handleCsvCreateButton()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // スケジュール指定リージョンのインスタンス
    XxcsoTaskAppSearchVOImpl taskAppSchVo = getXxcsoTaskAppSearchVO1();
    if ( taskAppSchVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoTaskAppSearchVOImpl");
    }

    // スケジュール指定リージョン行インスタンス
    XxcsoTaskAppSearchVORowImpl taskAppSchVoRow =
      (XxcsoTaskAppSearchVORowImpl) taskAppSchVo.first();
    if ( taskAppSchVoRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoTaskAppSearchVORowImpl");
    }

    // 指定日付の取得
    Date dateSch = taskAppSchVoRow.getDateSch();

    // 指定日付の入力チェック
    this.chkAppDate(dateSch);

    // 部署の入力チェックをし、検索対象の拠点コードを取得
    String baseCodeSch = this.chkBaseName(taskAppSchVoRow);

    // CSV実行SQL格納VOより、SQL文を取得
    XxcsoCsvQueryVOImpl csvQueryVo = getXxcsoCsvQueryVO1();
    if (csvQueryVo == null)
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoCsvQueryVOImpl");
    }
    String csvQuery = csvQueryVo.getQuery();

    // ****************************************
    // *****CSVデータ生成処理 Start************
    // ****************************************
    OracleCallableStatement stmt = null;
    OracleResultSet         rs   = null;

    // プロファイルの取得
    String clientEnc = txt.getProfile(XxcsoConstants.XXCSO1_CLIENT_ENCODE);
    if ( clientEnc == null || "".equals(clientEnc.trim()) )
    {
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoConstants.XXCSO1_CLIENT_ENCODE
        );
    }

    // CallableStatementによりQuery実行
    stmt = (OracleCallableStatement) txt.createCallableStatement(csvQuery, 0);

    StringBuffer sbFileData = new StringBuffer();
    try
    {
      // バインドへの値の設定
      int idx = 1;
      stmt.setString(idx++, baseCodeSch); // 拠点コード
      stmt.setString(idx++, baseCodeSch); // 拠点コード
      stmt.setString(idx++, baseCodeSch); // 拠点コード
      stmt.setString(idx++, dateSch.dateValue().toString()); // 日付
      stmt.setString(idx++, dateSch.dateValue().toString()); // 日付
      stmt.setString(idx++, dateSch.dateValue().toString()); // 日付

      rs = (OracleResultSet)stmt.executeQuery();

      while (rs.next())
      {
        // 出力用バッファへ格納
        int rsIdx = 1;
        // 項目:従業員番号
        sbFileData
          .append("\"").append(rs.getString(rsIdx++)).append("\"").append(",");
        // 項目:担当者名
        sbFileData
          .append("\"").append(rs.getString(rsIdx++)).append("\"").append(",");
        // 項目:月日
        sbFileData
          .append("\"").append(rs.getString(rsIdx++)).append("\"").append(",");
        // 項目:曜日
        sbFileData
          .append("\"").append(rs.getString(rsIdx++)).append("\"").append(",");
        // 項目:予定／実績
        sbFileData
          .append("\"").append(rs.getString(rsIdx++)).append("\"").append(",");
        // 項目:タスク詳細
        sbFileData
          .append("\"").append(rs.getString(rsIdx++)).append("\"").append("\n");
      }
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txt, e);

      throw
        XxcsoMessage.createSqlErrorMessage(
          e
          ,XxcsoConstants.TOKEN_VALUE_CSV_CREATE
        );
    }
    finally
    {
      try
      {
        if ( rs != null )
        {
          rs.close();
        }
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txt, e);

        throw
          XxcsoMessage.createSqlErrorMessage(
            e
            ,XxcsoConstants.TOKEN_VALUE_CSV_CREATE
          );
      }
    }
    // ****************************************
    // *****CSVデータ生成処理 End**************
    // ****************************************

    // VOへのファイル名、ファイルデータの設定
    XxcsoCsvDownVOImpl csvVo = getXxcsoCsvDownVO1();
    if ( csvVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoCsvDownVOImpl");
    }

    XxcsoCsvDownVORowImpl csvRowVo
      = (XxcsoCsvDownVORowImpl)csvVo.createRow();

    // *****CSVファイル名用日付文字列(yyyymmdd)
    StringBuffer sbDate = new StringBuffer(8);
    String nowDate = txt.getCurrentUserDate().dateValue().toString();
    sbDate.append(nowDate.substring(0, 4));
    sbDate.append(nowDate.substring(5, 7));
    sbDate.append(nowDate.substring(8, 10));

    // *****CSVファイル名の生成(ユーザー名_yyyymmdd_連番)
    StringBuffer sbFileName = new StringBuffer(120);
    sbFileName.append(txt.getUserName());
    sbFileName.append(XxcsoWeeklyTaskViewConstants.CSV_NAME_DELIMITER);
    sbFileName.append(sbDate);
    sbFileName.append(XxcsoWeeklyTaskViewConstants.CSV_NAME_DELIMITER);
    sbFileName.append((csvVo.getRowCount() + 1));
    sbFileName.append(XxcsoWeeklyTaskViewConstants.CSV_EXTENSION);

    try
    {
      // *****ファイル名、ファイルデータを設定
      csvRowVo.setFileName(new String(sbFileName));
      csvRowVo.setFileData(
        new BlobDomain(sbFileData.toString().getBytes(clientEnc))
      );
    }
    catch (UnsupportedEncodingException uae)
    {
      throw
          XxcsoMessage.createCsvErrorMessage(uae);
    }

    csvVo.last();
    csvVo.next();
    csvVo.insertRow(csvRowVo);

    // 成功メッセージを設定する
    StringBuffer sbMsg = new StringBuffer();
    sbMsg.append(XxcsoWeeklyTaskViewConstants.MSG_DISP_CSV);
    sbMsg.append(sbFileName);

    mMessage
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
          ,XxcsoConstants.TOKEN_RECORD
          ,new String(sbMsg)
          ,XxcsoConstants.TOKEN_ACTION
          ,XxcsoWeeklyTaskViewConstants.MSG_DISP_OUT
        );

    XxcsoUtils.debug(txt, "[END]");

    return;
  }

  /*****************************************************************************
   * 表示ボタン押下時処理
   * @throw OAException 担当者未選択エラー
   *                     担当者超過エラー
   *****************************************************************************
   */
  public String handleShowButton()
  {

    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // スケジュール指定リージョンのインスタンス
    XxcsoTaskAppSearchVOImpl taskAppSchVo = getXxcsoTaskAppSearchVO1();
    if ( taskAppSchVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoTaskAppSearchVOImpl");
    }

    // スケジュール指定リージョン行インスタンス
    XxcsoTaskAppSearchVORowImpl taskAppSchVoRow =
      (XxcsoTaskAppSearchVORowImpl) taskAppSchVo.first();
    if ( taskAppSchVoRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoTaskAppSearchVORowImpl");
    }

    // 担当者選択リージョンのインスタンス
    XxcsoEmpSelSummaryVOImpl empSelVo = getXxcsoEmpSelSummaryVO1();
    if ( empSelVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoEmpSelSummaryVOImpl");
    }

    // 指定日付の取得
    Date dateSch = taskAppSchVoRow.getDateSch();
    // 拠点コードの取得
    String baseCodeSch = taskAppSchVoRow.getBaseCode();
    
    // 指定日付の入力チェック
    this.chkAppDate(dateSch);


    // 担当者選択リージョンの行インスタンス
    XxcsoEmpSelSummaryVORowImpl empSelVoRow =
      (XxcsoEmpSelSummaryVORowImpl) empSelVo.first();

    // 選択値格納用List(最大10件のため10で初期化)
    List chkdList = new ArrayList(10);

    int chkCnt = 0;
    
    // 全行をFetch
    while ( empSelVoRow != null )
    {
      // 選択CheckBox=ONのオブジェクトを抽出
      if( "Y".equals(empSelVoRow.getSelectFlg()) )
      {
        chkCnt++;
        
        // 担当者選択超過チェック
        if ( chkCnt > XxcsoWeeklyTaskViewConstants.MAX_SIZE_INT ) 
        {
          // 担当者選択超過エラー
          throw
            XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00047
              ,XxcsoConstants.TOKEN_ITEM
              ,XxcsoWeeklyTaskViewConstants.MSG_DISP_EMPSEL
              ,XxcsoConstants.TOKEN_SIZE
              ,XxcsoWeeklyTaskViewConstants.MAX_SIZE_STR
            );
        }
        // ユーザーIDを退避
        chkdList.add(empSelVoRow.getUserId().stringValue());

      }
      
      empSelVoRow = (XxcsoEmpSelSummaryVORowImpl) empSelVo.next();
    }

    // 選択チェック(超過チェックは上処理while内にて実施)
    if ( chkCnt == 0 )
    {
      // 担当者未選択エラー
      throw
        XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00229);
    }

    StringBuffer urlParam = new StringBuffer(100);
    urlParam.append(dateSch.toString());
    urlParam.append("|").append(baseCodeSch);
    for ( int i = 0; i < chkdList.size(); i++ )
    {
      urlParam.append("|").append((String)chkdList.get(i));
    }

    XxcsoUtils.debug(txt, "URL PARAMETER = " + urlParam.toString());
    
    XxcsoUtils.debug(txt, "[END]");

    return urlParam.toString();
  }

  /*****************************************************************************
   * メッセージを取得します。
   * @return mMessage
   *****************************************************************************
   */
  public OAException getMessage()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");
    XxcsoUtils.debug(txt, "[END]");

    return mMessage;

  }

  /*****************************************************************************
   * ログインユーザーのリソースIDを取得します
   * @return ログインユーザーのリーソースID
   *****************************************************************************
   */
  public String getLoginResourceId()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // スケジュール指定リージョンのインスタンス
    XxcsoTaskAppSearchVOImpl taskAppSchVo = getXxcsoTaskAppSearchVO1();
    if ( taskAppSchVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoTaskAppSearchVOImpl");
    }

    // スケジュール指定リージョン行インスタンス
    XxcsoTaskAppSearchVORowImpl taskAppSchVoRow =
      (XxcsoTaskAppSearchVORowImpl) taskAppSchVo.first();
    if ( taskAppSchVoRow == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoTaskAppSearchVORowImpl");
    }

    Number loginResourceId = taskAppSchVoRow.getLoginResourceId();
    if ( loginResourceId == null)
    {
      // リソースID未設定時はエラーとする
      throw
        XxcsoMessage.createErrorMessage( XxcsoConstants.APP_XXCSO1_00546 );
    }

    XxcsoUtils.debug(txt, "[END]");

    return loginResourceId.toString();
  }

  /*****************************************************************************
   * 指定日付入力チェック
   * @param  date 指定日付
   * @throw  OAException 日付未指定エラー
   *****************************************************************************
   */
  private void chkAppDate(Date date)
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    if ( date == null || "".equals(date) )
    {
      // エラー：日付未指定
      throw
        XxcsoMessage.createErrorMessage(
               XxcsoConstants.APP_XXCSO1_00005
              ,XxcsoConstants.TOKEN_COLUMN
              ,XxcsoWeeklyTaskViewConstants.MSG_DISP_DATE
        );
    }

    XxcsoUtils.debug(txt, "[END]");

    return;
  }

  /*****************************************************************************
   * 部署名入力チェック
   * @param taskSumVoRow スケジュール指定リージョンのVO行インスタンス
   * @return 検索対象の拠点コード
   *****************************************************************************
   */
  private String chkBaseName(XxcsoTaskAppSearchVORowImpl taskAppSchVoRow)
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    String retBaseCode = "";

    String inpBaseName = taskAppSchVoRow.getBaseName();
    if ( inpBaseName == null || "".equals(inpBaseName.trim()) )
    {
      // 未入力時はログインユーザーの基準勤務先拠点コードから取得
      retBaseCode = taskAppSchVoRow.getBaseLineBaseCode(); 
    }
    else
    {
      // 入力時は部署選択LOVで選択された値から取得
      retBaseCode = taskAppSchVoRow.getBaseCode();
    }

    XxcsoUtils.debug(txt, "[END]");

    return retBaseCode;
  }

  /*****************************************************************************
   * スケジュールリージョン内容作成
   * @param appDate スケジュール指定リージョンの日付
   * @param list    担当選択リージョン選択項目のList<Map>
   *****************************************************************************
   */
  private void createTaskInfo(
     Date  appDate
    ,List  list
    )
  {

    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    int size = list.size();
    int instCnt = 0;
    for ( int i = 0; i < size; i++ )
    {
      Map map = (HashMap)list.get(i);
      instCnt = i + 1;
      
      // スケジュール（担当者）の表示
      XxcsoEmpNameSummaryVOImpl empNameVo = (XxcsoEmpNameSummaryVOImpl)
        findViewObject("XxcsoEmpNameSummaryVO" + instCnt);
      if ( empNameVo == null )
      {
        throw XxcsoMessage.
          createInstanceLostError("XxcsoEmpNameSummaryVO" + instCnt);
      }
      empNameVo.initQuery(
        (String) map.get(XxcsoWeeklyTaskViewConstants.EMP_NAME)
      );

      // スケジュール（スケジュール）の表示
      XxcsoTaskSummaryVOImpl taskSumVo = (XxcsoTaskSummaryVOImpl)
        findViewObject("XxcsoTaskSummaryVO" + instCnt);
      if ( taskSumVo == null )
      {
        throw XxcsoMessage.
          createInstanceLostError("XxcsoTaskSummaryVO" + instCnt);
      }
      taskSumVo.initQuery(
        appDate.dateValue().toString(),
        (Number) map.get(XxcsoWeeklyTaskViewConstants.RESOURCE_ID)
      );
    }

    XxcsoUtils.debug(txt, "[END]");

  }

  /*****************************************************************************
   * 担当者選択リージョン属性設定VO初期化
   *****************************************************************************
   */
  private void initEmpSelRender()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    XxcsoEmpSelRenderVOImpl renderVo = getXxcsoEmpSelRenderVO1();
    if ( renderVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoEmpSelRenderVOImpl");
    }
    renderVo.executeQuery();

    XxcsoUtils.debug(txt, "[END]");
  }

  /*****************************************************************************
   * 担当者選択リージョン属性設定
   * @param isRender true:表示、false:非表示
   *****************************************************************************
   */
  private void setEmpSelItemAttribute(boolean isRender)
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    XxcsoEmpSelRenderVOImpl renderVo = getXxcsoEmpSelRenderVO1();
    if ( renderVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoEmpSelRenderVOImpl");
    }

    XxcsoEmpSelRenderVORowImpl renderVoRow =
      (XxcsoEmpSelRenderVORowImpl) renderVo.first();
    if ( renderVoRow == null )
    {
      throw XxcsoMessage.
        createInstanceLostError("XxcsoEmpSelRenderVORowImpl");
    }

    if ( isRender )
    {
      renderVoRow.setEmpSelRender(Boolean.TRUE);
    }
    else
    {
      renderVoRow.setEmpSelRender(Boolean.FALSE);
    }

    XxcsoUtils.debug(txt, "[END]");

  }

  /*****************************************************************************
   * スケジュールリージョン属性設定VO初期化
   *****************************************************************************
   */
  private void initTaskRender()
  {
    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    int instCnt = 0;
    for ( int i = 0; i < XxcsoWeeklyTaskViewConstants.MAX_SIZE_INT; i++ )
    {
      instCnt = i + 1;

      XxcsoTaskRenderVOImpl renderVo = (XxcsoTaskRenderVOImpl)
        findViewObject("XxcsoTaskRenderVO" + instCnt);
      if ( renderVo == null )
      {
        throw XxcsoMessage.
          createInstanceLostError("XxcsoTaskRenderVO" + instCnt);
      }

      renderVo.executeQuery();
    }

    XxcsoUtils.debug(txt, "[END]");

  }
  /*****************************************************************************
   * スケジュールの表示属性を設定します。
   * @param setSize 設定済みの行カウント
   *****************************************************************************
   */
  private void setTaskItemAttribute(int setSize)
  {

    OADBTransaction txt = getOADBTransaction();
    XxcsoUtils.debug(txt, "[START]");

    // ****************************************
    // *****表示可能スケジュールの設定*********
    // ****************************************
    // 引数の設定済み行数分render=trueに設定
    int instCnt1 = 0;
    for (int i = 0; i < setSize; i++)
    {
      instCnt1 = i + 1;

      XxcsoTaskRenderVOImpl renderVo = (XxcsoTaskRenderVOImpl)
        findViewObject("XxcsoTaskRenderVO" + instCnt1);
      if ( renderVo == null )
      {
        throw XxcsoMessage.
          createInstanceLostError("XxcsoTaskRenderVO" + instCnt1);
      }

      XxcsoTaskRenderVORowImpl renderVoRow =
        (XxcsoTaskRenderVORowImpl) renderVo.first();
      if ( renderVoRow == null )
      {
        throw XxcsoMessage.
          createInstanceLostError("XxcsoTaskRenderVORow" + instCnt1);
      }
      renderVoRow.setTaskRender(Boolean.TRUE);
    }

    // ****************************************
    // *****表示不可スケジュールの設定*********
    // ****************************************
    // 引数の設定済み行数から始まるカウントでMAX_SIZE_INTまでrender=falseに設定
    int instCnt2 = 0;
    for ( int j = setSize; j < XxcsoWeeklyTaskViewConstants.MAX_SIZE_INT; j++ )
    {
      instCnt2 = j + 1;

      XxcsoTaskRenderVOImpl renderVo = (XxcsoTaskRenderVOImpl)
        findViewObject("XxcsoTaskRenderVO" + instCnt2);
      if ( renderVo == null )
      {
        throw XxcsoMessage.
          createInstanceLostError("XxcsoTaskRenderVO" + instCnt2);
      }

      XxcsoTaskRenderVORowImpl renderVoRow =
        (XxcsoTaskRenderVORowImpl) renderVo.first();
      if ( renderVoRow == null )
      {
        throw XxcsoMessage.
          createInstanceLostError("XxcsoTaskRenderVORow" + instCnt1);
      }
      renderVoRow.setTaskRender(Boolean.FALSE);
    }

    XxcsoUtils.debug(txt, "[END]");

  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso008001j.server", "Xxcso008001jAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoEmpSelSummaryVO1
   */
  public XxcsoEmpSelSummaryVOImpl getXxcsoEmpSelSummaryVO1()
  {
    return (XxcsoEmpSelSummaryVOImpl)findViewObject("XxcsoEmpSelSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoEmpNameSummaryVO1
   */
  public XxcsoEmpNameSummaryVOImpl getXxcsoEmpNameSummaryVO1()
  {
    return (XxcsoEmpNameSummaryVOImpl)findViewObject("XxcsoEmpNameSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoEmpNameSummaryVO2
   */
  public XxcsoEmpNameSummaryVOImpl getXxcsoEmpNameSummaryVO2()
  {
    return (XxcsoEmpNameSummaryVOImpl)findViewObject("XxcsoEmpNameSummaryVO2");
  }

  /**
   * 
   * Container's getter for XxcsoEmpNameSummaryVO3
   */
  public XxcsoEmpNameSummaryVOImpl getXxcsoEmpNameSummaryVO3()
  {
    return (XxcsoEmpNameSummaryVOImpl)findViewObject("XxcsoEmpNameSummaryVO3");
  }

  /**
   * 
   * Container's getter for XxcsoEmpNameSummaryVO4
   */
  public XxcsoEmpNameSummaryVOImpl getXxcsoEmpNameSummaryVO4()
  {
    return (XxcsoEmpNameSummaryVOImpl)findViewObject("XxcsoEmpNameSummaryVO4");
  }

  /**
   * 
   * Container's getter for XxcsoEmpNameSummaryVO5
   */
  public XxcsoEmpNameSummaryVOImpl getXxcsoEmpNameSummaryVO5()
  {
    return (XxcsoEmpNameSummaryVOImpl)findViewObject("XxcsoEmpNameSummaryVO5");
  }

  /**
   * 
   * Container's getter for XxcsoEmpNameSummaryVO6
   */
  public XxcsoEmpNameSummaryVOImpl getXxcsoEmpNameSummaryVO6()
  {
    return (XxcsoEmpNameSummaryVOImpl)findViewObject("XxcsoEmpNameSummaryVO6");
  }

  /**
   * 
   * Container's getter for XxcsoEmpNameSummaryVO7
   */
  public XxcsoEmpNameSummaryVOImpl getXxcsoEmpNameSummaryVO7()
  {
    return (XxcsoEmpNameSummaryVOImpl)findViewObject("XxcsoEmpNameSummaryVO7");
  }

  /**
   * 
   * Container's getter for XxcsoEmpNameSummaryVO8
   */
  public XxcsoEmpNameSummaryVOImpl getXxcsoEmpNameSummaryVO8()
  {
    return (XxcsoEmpNameSummaryVOImpl)findViewObject("XxcsoEmpNameSummaryVO8");
  }

  /**
   * 
   * Container's getter for XxcsoEmpNameSummaryVO9
   */
  public XxcsoEmpNameSummaryVOImpl getXxcsoEmpNameSummaryVO9()
  {
    return (XxcsoEmpNameSummaryVOImpl)findViewObject("XxcsoEmpNameSummaryVO9");
  }

  /**
   * 
   * Container's getter for XxcsoEmpNameSummaryVO10
   */
  public XxcsoEmpNameSummaryVOImpl getXxcsoEmpNameSummaryVO10()
  {
    return (XxcsoEmpNameSummaryVOImpl)findViewObject("XxcsoEmpNameSummaryVO10");
  }

  /**
   * 
   * Container's getter for XxcsoTaskSummaryVO1
   */
  public XxcsoTaskSummaryVOImpl getXxcsoTaskSummaryVO1()
  {
    return (XxcsoTaskSummaryVOImpl)findViewObject("XxcsoTaskSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoTaskSummaryVO2
   */
  public XxcsoTaskSummaryVOImpl getXxcsoTaskSummaryVO2()
  {
    return (XxcsoTaskSummaryVOImpl)findViewObject("XxcsoTaskSummaryVO2");
  }

  /**
   * 
   * Container's getter for XxcsoTaskSummaryVO3
   */
  public XxcsoTaskSummaryVOImpl getXxcsoTaskSummaryVO3()
  {
    return (XxcsoTaskSummaryVOImpl)findViewObject("XxcsoTaskSummaryVO3");
  }

  /**
   * 
   * Container's getter for XxcsoTaskSummaryVO4
   */
  public XxcsoTaskSummaryVOImpl getXxcsoTaskSummaryVO4()
  {
    return (XxcsoTaskSummaryVOImpl)findViewObject("XxcsoTaskSummaryVO4");
  }

  /**
   * 
   * Container's getter for XxcsoTaskSummaryVO5
   */
  public XxcsoTaskSummaryVOImpl getXxcsoTaskSummaryVO5()
  {
    return (XxcsoTaskSummaryVOImpl)findViewObject("XxcsoTaskSummaryVO5");
  }

  /**
   * 
   * Container's getter for XxcsoTaskSummaryVO6
   */
  public XxcsoTaskSummaryVOImpl getXxcsoTaskSummaryVO6()
  {
    return (XxcsoTaskSummaryVOImpl)findViewObject("XxcsoTaskSummaryVO6");
  }

  /**
   * 
   * Container's getter for XxcsoTaskSummaryVO7
   */
  public XxcsoTaskSummaryVOImpl getXxcsoTaskSummaryVO7()
  {
    return (XxcsoTaskSummaryVOImpl)findViewObject("XxcsoTaskSummaryVO7");
  }

  /**
   * 
   * Container's getter for XxcsoTaskSummaryVO8
   */
  public XxcsoTaskSummaryVOImpl getXxcsoTaskSummaryVO8()
  {
    return (XxcsoTaskSummaryVOImpl)findViewObject("XxcsoTaskSummaryVO8");
  }

  /**
   * 
   * Container's getter for XxcsoTaskSummaryVO9
   */
  public XxcsoTaskSummaryVOImpl getXxcsoTaskSummaryVO9()
  {
    return (XxcsoTaskSummaryVOImpl)findViewObject("XxcsoTaskSummaryVO9");
  }

  /**
   * 
   * Container's getter for XxcsoTaskSummaryVO10
   */
  public XxcsoTaskSummaryVOImpl getXxcsoTaskSummaryVO10()
  {
    return (XxcsoTaskSummaryVOImpl)findViewObject("XxcsoTaskSummaryVO10");
  }

  /**
   * 
   * Container's getter for XxcsoCsvDownVO1
   */
  public XxcsoCsvDownVOImpl getXxcsoCsvDownVO1()
  {
    return (XxcsoCsvDownVOImpl)findViewObject("XxcsoCsvDownVO1");
  }

  /**
   * 
   * Container's getter for XxcsoTaskAppSearchVO1
   */
  public XxcsoTaskAppSearchVOImpl getXxcsoTaskAppSearchVO1()
  {
    return (XxcsoTaskAppSearchVOImpl)findViewObject("XxcsoTaskAppSearchVO1");
  }

  /**
   * 
   * Container's getter for XxcsoTaskRenderVO1
   */
  public XxcsoTaskRenderVOImpl getXxcsoTaskRenderVO1()
  {
    return (XxcsoTaskRenderVOImpl)findViewObject("XxcsoTaskRenderVO1");
  }

  /**
   * 
   * Container's getter for XxcsoTaskRenderVO2
   */
  public XxcsoTaskRenderVOImpl getXxcsoTaskRenderVO2()
  {
    return (XxcsoTaskRenderVOImpl)findViewObject("XxcsoTaskRenderVO2");
  }

  /**
   * 
   * Container's getter for XxcsoTaskRenderVO3
   */
  public XxcsoTaskRenderVOImpl getXxcsoTaskRenderVO3()
  {
    return (XxcsoTaskRenderVOImpl)findViewObject("XxcsoTaskRenderVO3");
  }

  /**
   * 
   * Container's getter for XxcsoTaskRenderVO4
   */
  public XxcsoTaskRenderVOImpl getXxcsoTaskRenderVO4()
  {
    return (XxcsoTaskRenderVOImpl)findViewObject("XxcsoTaskRenderVO4");
  }

  /**
   * 
   * Container's getter for XxcsoTaskRenderVO5
   */
  public XxcsoTaskRenderVOImpl getXxcsoTaskRenderVO5()
  {
    return (XxcsoTaskRenderVOImpl)findViewObject("XxcsoTaskRenderVO5");
  }

  /**
   * 
   * Container's getter for XxcsoTaskRenderVO6
   */
  public XxcsoTaskRenderVOImpl getXxcsoTaskRenderVO6()
  {
    return (XxcsoTaskRenderVOImpl)findViewObject("XxcsoTaskRenderVO6");
  }

  /**
   * 
   * Container's getter for XxcsoTaskRenderVO7
   */
  public XxcsoTaskRenderVOImpl getXxcsoTaskRenderVO7()
  {
    return (XxcsoTaskRenderVOImpl)findViewObject("XxcsoTaskRenderVO7");
  }

  /**
   * 
   * Container's getter for XxcsoTaskRenderVO8
   */
  public XxcsoTaskRenderVOImpl getXxcsoTaskRenderVO8()
  {
    return (XxcsoTaskRenderVOImpl)findViewObject("XxcsoTaskRenderVO8");
  }

  /**
   * 
   * Container's getter for XxcsoTaskRenderVO9
   */
  public XxcsoTaskRenderVOImpl getXxcsoTaskRenderVO9()
  {
    return (XxcsoTaskRenderVOImpl)findViewObject("XxcsoTaskRenderVO9");
  }

  /**
   * 
   * Container's getter for XxcsoTaskRenderVO10
   */
  public XxcsoTaskRenderVOImpl getXxcsoTaskRenderVO10()
  {
    return (XxcsoTaskRenderVOImpl)findViewObject("XxcsoTaskRenderVO10");
  }

  /**
   * 
   * Container's getter for XxcsoCsvQueryVO1
   */
  public XxcsoCsvQueryVOImpl getXxcsoCsvQueryVO1()
  {
    return (XxcsoCsvQueryVOImpl)findViewObject("XxcsoCsvQueryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoEmpSelRenderVO1
   */
  public XxcsoEmpSelRenderVOImpl getXxcsoEmpSelRenderVO1()
  {
    return (XxcsoEmpSelRenderVOImpl)findViewObject("XxcsoEmpSelRenderVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBaseSearchVO1
   */
  public XxcsoBaseSearchVOImpl getXxcsoBaseSearchVO1()
  {
    return (XxcsoBaseSearchVOImpl)findViewObject("XxcsoBaseSearchVO1");
  }


}