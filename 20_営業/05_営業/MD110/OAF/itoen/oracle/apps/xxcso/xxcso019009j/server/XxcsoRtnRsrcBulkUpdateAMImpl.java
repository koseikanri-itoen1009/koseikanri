/*============================================================================
* ファイル名 : XxcsoRtnRsrcBulkUpdateAMImpl
* 概要説明   : ルートNo/担当営業員一括更新画面アプリケーション・モジュールクラス
* バージョン : 1.7
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-16 1.0  SCS富尾和基  新規作成
* 2009-03-05 1.1  SCS柳平直人  [CT1-034]重複営業員エラー対応
* 2009-04-02 1.2  SCS阿部大輔  [T1_0092]担当営業員の顧客対応
* 2009-04-02 1.3  SCS阿部大輔  [T1_0125]担当営業員の行追加対応
* 2009-05-07 1.4  SCS柳平直人  [T1_0603]登録前検証処理方法修正
* 2009-08-19 1.5  SCS阿部大輔  [0001123]追加ボタン初期設定対応
* 2010-03-23 1.6  SCS阿部大輔  [E_本稼動_01942]管理元拠点対応
* 2015-09-08 1.7  SCSK桐生和幸 [E_本稼動_13307]ルート一括登録画面仕様変更対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.server;

import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.OAException;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;
import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;
import itoen.oracle.apps.xxcso.common.util.XxcsoValidateUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoRouteManagementUtils;
import itoen.oracle.apps.xxcso.xxcso019009j.util.XxcsoRtnRsrcBulkUpdateConstants;
import com.sun.java.util.collections.List;
import com.sun.java.util.collections.ArrayList;
import java.sql.SQLException;
import oracle.jbo.domain.Date;
// 2009-05-07 [T1_0708] Add Start
import oracle.apps.fnd.framework.server.OAPlsqlEntityImpl;
// 2009-05-07 [T1_0708] Add End


/*******************************************************************************
 * ルートNo/担当営業員一括更新画面のアプリケーション・モジュールクラス
 * @author  SCS富尾和基
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcBulkUpdateAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRtnRsrcBulkUpdateAMImpl()
  {
  }

  /*****************************************************************************
   * 初期化処理
   * @param mode         処理モード
   *****************************************************************************
   */
  public void initDetails(
    String mode
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoRtnRsrcBulkUpdateInitVOImpl initVo
      = getXxcsoRtnRsrcBulkUpdateInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateInitVO1"
        );
    }

    XxcsoRtnRsrcBulkUpdateSumVOImpl sumVo
      = getXxcsoRtnRsrcBulkUpdateSumVO1();
    if ( sumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateSumVO1"
        );
    }
    
    rollback();

    if ( ! initVo.isPreparedForExecution() )
    {
      initVo.executeQuery();
    }

    XxcsoRtnRsrcBulkUpdateInitVORowImpl initRow
      = (XxcsoRtnRsrcBulkUpdateInitVORowImpl)initVo.first();

    if ( XxcsoRtnRsrcBulkUpdateConstants.MODE_FIRE_ACTION.equals(mode) )
    {
      XxcsoRtnRsrcBulkUpdateSumVORowImpl sumRow
        = (XxcsoRtnRsrcBulkUpdateSumVORowImpl)sumVo.first();

      initRow.setEmployeeNumber(sumRow.getEmployeeNumber());
      initRow.setFullName(sumRow.getFullName());
      initRow.setRouteNo(sumRow.getRouteNo());
      initRow.setReflectMethod(initRow.getReflectMethod());
      initRow.setAddCustomerButtonRender(Boolean.TRUE);

// 2010-03-23 [E_本稼動_01942] Add Start
      initRow.setBaseCode1(sumRow.getBaseCode());
      initRow.setBaseName(sumRow.getBaseName());
// 2010-03-23 [E_本稼動_01942] Add End

      //適用ボタン押下後再検索処理
      reSearch();

    }
    else
    {
// 2010-03-23 [E_本稼動_01942] Add Start
      initRow.setBaseCode1(initRow.getLoginBaseCode());
      initRow.setBaseName(initRow.getLoginBaseName());
// 2010-03-23 [E_本稼動_01942] Add End
      initRow.setAddCustomerButtonRender(Boolean.FALSE);
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 進むボタン押下時処理
   *****************************************************************************
   */
  public void handleSearchButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoRtnRsrcBulkUpdateInitVOImpl initVo
      = getXxcsoRtnRsrcBulkUpdateInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateInitVO1"
        );
    }

    XxcsoRtnRsrcBulkUpdateSumVOImpl sumVo
      = getXxcsoRtnRsrcBulkUpdateSumVO1();
    if ( sumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateSumVO1"
        );
    }

    XxcsoRtnRsrcFullVOImpl registVo
      = getXxcsoRtnRsrcFullVO1();
    if ( registVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcFullVO1"
        );
    }

    //////////////////////////////////////
    // 変更確認
    //////////////////////////////////////
    if ( getTransaction().isDirty() )
    {
      throw XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00335);
    }
    //////////////////////////////////////
    // 各行を取得
    //////////////////////////////////////
    XxcsoRtnRsrcBulkUpdateInitVORowImpl initRow
      = (XxcsoRtnRsrcBulkUpdateInitVORowImpl)initVo.first();
    
    //////////////////////////////////////
    // 検索前検証処理
    //////////////////////////////////////
    chkBeforeSearch( txn, initRow );

    //////////////////////////////////////
    // 検索処理
    //////////////////////////////////////
    sumVo.initQuery(
      initRow.getEmployeeNumber()
     ,initRow.getFullName()
     ,initRow.getRouteNo()
// 2010-03-23 [E_本稼動_01942] Add Start
     ,initRow.getBaseCode1()
     ,initRow.getBaseName()
// 2010-03-23 [E_本稼動_01942] Add End
    );
    
    registVo.initQuery(
      initRow.getEmployeeNumber()
     ,initRow.getRouteNo()
// 2010-03-23 [E_本稼動_01942] Add Start
     //,initRow.getBaseCode()
     ,initRow.getBaseCode1()
// 2010-03-23 [E_本稼動_01942] Add End
    );

    // 各行のプロパティ設定
    XxcsoRtnRsrcFullVORowImpl registRow
      = (XxcsoRtnRsrcFullVORowImpl)registVo.first();
    
    /* 20090402_abe_T1_0092 START*/
    //if ( registRow != null )
    //{
    /* 20090402_abe_T1_0092 END*/
      initRow.setAddCustomerButtonRender(Boolean.TRUE);
      while ( registRow != null )
      {
        registRow.setAccountNumberReadOnly(Boolean.TRUE);

        registRow = (XxcsoRtnRsrcFullVORowImpl)registVo.next();
      }
    /* 20090402_abe_T1_0092 START*/
    //}
    //else
    //{
    //  initRow.setAddCustomerButtonRender(Boolean.FALSE);
    //}
    /* 20090402_abe_T1_0092 END*/

    //////////////////////////////////////
    // 検索後検証処理
    //////////////////////////////////////
    List list = chkAfterSearch( txn, registVo );

    if ( list.size() > 0 )
    {
      // エラーの出力と共に、追加ボタンを非表示
      initRow.setAddCustomerButtonRender(Boolean.FALSE);
      OAException.raiseBundledOAException( list );
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 追加ボタン押下時処理
   *****************************************************************************
   */
  public void handleAddCustomerButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    // プロファイル値の取得
    String maxSize = getVoMaxFetchSize( txn );

    XxcsoRtnRsrcFullVOImpl registVo
      = getXxcsoRtnRsrcFullVO1();
    if ( registVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcFullVO1"
        );
    }

    /* 20090819_abe_0001123 START*/
    XxcsoRtnRsrcBulkUpdateInitVOImpl initVo
      = getXxcsoRtnRsrcBulkUpdateInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateInitVO1"
        );
    }
    /* 20090819_abe_0001123 END*/

    int rowCount = registVo.getRowCount();

    XxcsoUtils.debug(txn, "検索件数上限： " + maxSize);
    XxcsoUtils.debug(txn, "検索結果件数： " + rowCount);

    // 追加上限チェック
    if ( rowCount >= Integer.parseInt(maxSize))
    {
      throw
        XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00010
         ,XxcsoConstants.TOKEN_OBJECT
         ,XxcsoRtnRsrcBulkUpdateConstants.TOKEN_VALUE_ACCOUNT_INFO
         ,XxcsoConstants.TOKEN_MAX_SIZE
         ,maxSize
        );
    }

    XxcsoRtnRsrcFullVORowImpl registRow
      = (XxcsoRtnRsrcFullVORowImpl)registVo.createRow();

    registRow.setAccountNumberReadOnly(Boolean.FALSE);

    /* 20090819_abe_0001123 START*/
    XxcsoRtnRsrcBulkUpdateInitVORowImpl initRow
      = (XxcsoRtnRsrcBulkUpdateInitVORowImpl)initVo.first();
    // 検索条件から新担当、新ルートNoを設定
    registRow.setNextResource(initRow.getEmployeeNumber());
    registRow.setNextRouteNo(initRow.getRouteNo());
    /* 20090819_abe_0001123 END*/
    
    registVo.first();
    registVo.insertRow(registRow);

    XxcsoUtils.debug(txn, "[END]");
  }
  
  /*****************************************************************************
   * 消去ボタン押下時処理
   *****************************************************************************
   */
  public void handleClearButton()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoRtnRsrcBulkUpdateInitVOImpl initVo
      = getXxcsoRtnRsrcBulkUpdateInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateInitVO1"
        );
    }

    initVo.executeQuery();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 適用ボタン押下時処理
   *****************************************************************************
   */
  public OAException handleSubmitButton()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    if ( ! getTransaction().isDirty() )
    {
      throw XxcsoMessage.createNotChangedMessage();
    }

    XxcsoRtnRsrcBulkUpdateInitVOImpl initVo
      = getXxcsoRtnRsrcBulkUpdateInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateInitVO1"
        );
    }

    XxcsoRtnRsrcFullVOImpl registVo
      = getXxcsoRtnRsrcFullVO1();
    if ( registVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcFullVO1"
        );
    }

// 2010-03-23 [E_本稼動_01942] Add Start
    XxcsoRtnRsrcBulkUpdateSumVOImpl sumVo
      = getXxcsoRtnRsrcBulkUpdateSumVO1();
    if ( sumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateSumVO1"
        );
    }
// 2010-03-23 [E_本稼動_01942] Add End
    
    //////////////////////////////////////
    // 各行を取得
    //////////////////////////////////////
    XxcsoRtnRsrcBulkUpdateInitVORowImpl initRow
      = (XxcsoRtnRsrcBulkUpdateInitVORowImpl)initVo.first();
// 2010-03-23 [E_本稼動_01942] Add Start
      XxcsoRtnRsrcBulkUpdateSumVORowImpl sumRow
        = (XxcsoRtnRsrcBulkUpdateSumVORowImpl)sumVo.first();
// 2010-03-23 [E_本稼動_01942] Add End
    
    //////////////////////////////////////
    // 登録前検証処理
    //////////////////////////////////////
// 2010-03-23 [E_本稼動_01942] Add Start
    //chkBeforeSubmit( txn, initRow,  registVo);
    chkBeforeSubmit( txn, initRow,  sumRow,  registVo);
// 2010-03-23 [E_本稼動_01942] Add End
    //////////////////////////////////////
    // 適用開始日判定
    //////////////////////////////////////
    Date trgtResourceStartDate = null;
    Date nextResourceStartDate = null;
    Date trgtRouteNoStartDate = null;
    Date nextRouteNoStartDate = null;

    // 「反映方法」=即時反映
    if ( (XxcsoRtnRsrcBulkUpdateConstants.REFLECT_TRGT).equals(
           initRow.getReflectMethod() ) )
    {
      // 現担当適用開始日     :業務処理日付
      trgtResourceStartDate = initRow.getCurrentDate();

      // 現ルートNo適用開始日 :業務処理日付の翌月１日
      trgtRouteNoStartDate  = initRow.getFirstDate();

      // 新担当適用開始日     :業務処理日付
      nextResourceStartDate = initRow.getCurrentDate();

      // 新ルートNo適用開始日 :業務処理日付の翌月１日
      nextRouteNoStartDate  = initRow.getFirstDate();

    // 「反映方法」=予約反映  
    }
    else 
    {
      //現担当適用開始日      :業務処理日付の翌月１日
      trgtResourceStartDate = initRow.getNextDate();

      //現ルートNo適用開始日  :業務処理日付の翌月１日
      trgtRouteNoStartDate  = initRow.getNextDate();

      //新担当適用開始日      :業務処理日付の翌月１日
      nextResourceStartDate = initRow.getNextDate();

      //新ルートNo適用開始日  :業務処理日付の翌月１日
      nextRouteNoStartDate  = initRow.getNextDate();
    }

    //////////////////////////////////////
    // 登録用VOへ適用開始日設定
    //////////////////////////////////////
    XxcsoRtnRsrcFullVORowImpl registRow
      = (XxcsoRtnRsrcFullVORowImpl)registVo.first();

    while ( registRow != null )
    {

      registRow.setTrgtResourceStartDate(trgtResourceStartDate);
      registRow.setTrgtRouteNoStartDate(trgtRouteNoStartDate);
      registRow.setNextResourceStartDate(nextResourceStartDate);
      registRow.setNextRouteNoStartDate(nextRouteNoStartDate);
      registRow = (XxcsoRtnRsrcFullVORowImpl)registVo.next();
    }

    //////////////////////////////////////
    // 登録・更新処理
    //////////////////////////////////////
    commit();

    /* 20090402_abe_T1_0125 START*/
    registRow
      = (XxcsoRtnRsrcFullVORowImpl)registVo.first();
    while ( registRow != null )
    {
        //追加ボタンで未入力の場合は行を削除
        if ( (( registRow.getNextResource() == null)
          || registRow.getNextResource().equals(""))
          || ((registRow.getNextRouteNo() == null)
          || registRow.getNextRouteNo().equals(""))
        /* 20090819_abe_0001123 START*/
          || ((registRow.getAccountNumber() == null)
          || registRow.getAccountNumber().equals(""))
        /* 20090819_abe_0001123 END*/
          )
        {
          registRow.remove();
        }
      registRow = (XxcsoRtnRsrcFullVORowImpl)registVo.next();
    }
    /* 20090402_abe_T1_0125 END*/

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoRtnRsrcBulkUpdateConstants.TOKEN_VALUE_PROCESS
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoConstants.TOKEN_VALUE_COMPLETE
        ); 
    
    XxcsoUtils.debug(txn, "[END]");

    return msg;
  }

  /*****************************************************************************
   * 取消ボタン押下時処理
   *****************************************************************************
   */
  public void handleCancelButton()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    rollback();
    
    XxcsoUtils.debug(txn, "[END]");
  }

    /*****************************************************************************
   * 各ポップリストの初期化処理
   *****************************************************************************
   */
  public void initPopList()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // 反映方法
    XxcsoLookupListVOImpl appListVo
      = getXxcsoReflectMethodListVO();
    if ( appListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoReflectMethodListVO");
    }

    appListVo.initQuery(
      "XXCSO1_REFLECT_METHOD"
     ,"lookup_code"
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * コミット処理
   *****************************************************************************
   */
  private void commit()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoRouteManagementUtils.getInstance().commitTransaction(txn);

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ロールバック処理
   *****************************************************************************
   */
  private void rollback()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    if ( getTransaction().isDirty() )
    {
      getTransaction().rollback();
    }

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 検索前検証処理
   * @param txn         OADBTransactionインスタンス
   * @param initRow     対象指定リージョン情報
   *****************************************************************************
   */
  private void chkBeforeSearch(
    OADBTransaction txn
   ,XxcsoRtnRsrcBulkUpdateInitVORowImpl initRow
  )
  {

    XxcsoUtils.debug(txn, "[START]");

    List errorList = new ArrayList();
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);

    //画面項目「拠点ＣＤ」必須チェック
    errorList
      = util.requiredCheck(
          errorList
         ,initRow.getBaseCode1()
         ,XxcsoRtnRsrcBulkUpdateConstants.TOKEN_VALUE_BASECODE
         ,0
        );

    //画面項目「営業員コード」必須チェック
    errorList
      = util.requiredCheck(
          errorList
         ,initRow.getEmployeeNumber()
         ,XxcsoRtnRsrcBulkUpdateConstants.TOKEN_VALUE_EMPLOYEENUMBER
         ,0
        );

    //画面項目「ルートNo」妥当性チェック
    if ( ! chkRouteNo( txn , initRow.getRouteNo() ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00046,
            XxcsoConstants.TOKEN_ENTRY,
            XxcsoRtnRsrcBulkUpdateConstants.TOKEN_VALUE_ROUTENO,
            XxcsoConstants.TOKEN_VALUES,
            initRow.getRouteNo()
          );
      errorList.add(error);
    }
    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 検索後検証処理
   * @param txn         OADBTransactionインスタンス
   * @param registVo    一括更新リージョン情報
   * @return エラーメッセージ
   *****************************************************************************
   */
  private List chkAfterSearch(
    OADBTransaction        txn
   ,XxcsoRtnRsrcFullVOImpl registVo
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    List errorList = new ArrayList();

    // プロファイル値の取得
    String maxSize = getVoMaxFetchSize( txn );

    // 検索結果件数の取得
    int rowCount = registVo.getRowCount();

    XxcsoUtils.debug(txn, "検索件数上限： " + maxSize);
    XxcsoUtils.debug(txn, "検索結果件数： " + rowCount);

    //検索件数チェック
    if ( rowCount > Integer.parseInt( maxSize ) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00424
          );
      errorList.add(error);
    }

    // プロファイルのエラー時は検索結果を表示し、終了
    if ( errorList.size() > 0 )
    {
      return errorList;
    }

    XxcsoRtnRsrcFullVORowImpl registRow
      = (XxcsoRtnRsrcFullVORowImpl)registVo.first();

    while ( registRow != null )
    {
      // 現担当、新担当が期間重複で複数設定されていないかチェック
      if ( registRow.getTrgtResourceCnt().intValue() > 1 ||
           registRow.getNextResourceCnt().intValue() > 1
      )
      {
        // 重複営業員存在エラー
        OAException error
          = XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00555
             ,XxcsoConstants.TOKEN_ACCOUNT
             ,registRow.getPartyName()
            );
        errorList.add(error);
      }
      registRow = (XxcsoRtnRsrcFullVORowImpl) registVo.next();
    }

    // 重複エラー時は検索結果を全件表示しない
    if ( errorList.size() > 0 )
    {
      // 0件となる検索条件でVOを初期化
      registVo.initQuery(
        ""
       ,""
       ,""
       );
    }

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * 登録前検証処理
   * @param txn         OADBTransactionインスタンス
   * @param initRow     対象指定リージョン情報
   * @param sumRow      対象指定リージョンビュー情報
   * @param registVo    一括更新リージョン情報
   *****************************************************************************
   */
  private void chkBeforeSubmit(
    OADBTransaction                     txn
   ,XxcsoRtnRsrcBulkUpdateInitVORowImpl initRow
// 2010-03-23 [E_本稼動_01942] Add Start
   ,XxcsoRtnRsrcBulkUpdateSumVORowImpl  sumRow
// 2010-03-23 [E_本稼動_01942] Add End
   ,XxcsoRtnRsrcFullVOImpl              registVo
  )
  { 
  
    XxcsoUtils.debug(txn, "[START]");
  
    List errorList = new ArrayList();
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);

    XxcsoRtnRsrcFullVORowImpl registRow
      = (XxcsoRtnRsrcFullVORowImpl)registVo.first();

    int index = 0;
// 2010-03-23 [E_本稼動_01942] Add Start
    //String  baseCode      = initRow.getBaseCode();
    String  baseCode      = sumRow.getBaseCode();
// 2010-03-23 [E_本稼動_01942] Add End
    List    coAccountList = new ArrayList();
    boolean isRsvAccount  = false;
    boolean isSameErr     = false;
    
    while ( registRow != null )
    {
      index++;

      //////////////////////////////////////
      // DEBUGログ出力
      //////////////////////////////////////
      XxcsoUtils.debug(txn, "顧客コード          ："
                              + registRow.getAccountNumber()                  );
      XxcsoUtils.debug(txn, "顧客名              ："
                              + registRow.getPartyName()                      );
      XxcsoUtils.debug(txn, "顧客ID              ："
                              + registRow.getCustAccountId()                  );
      XxcsoUtils.debug(txn, "作成者              ："
                              + registRow.getCreatedBy()                      );
      XxcsoUtils.debug(txn, "作成日              ："
                              + registRow.getCreationDate()                   );
      XxcsoUtils.debug(txn, "最終更新者          ："
                              + registRow.getLastUpdatedBy()                  );
      XxcsoUtils.debug(txn, "最終更新日          ："
                              + registRow.getLastUpdateDate()                 );
      XxcsoUtils.debug(txn, "最終更新R           ："
                              + registRow.getLastUpdateLogin()                );
      XxcsoUtils.debug(txn, "現ルートNo          ："
                              + registRow.getTrgtRouteNo()                    );
      XxcsoUtils.debug(txn, "現ルートNo適用開始日："
                              + registRow.getTrgtRouteNoStartDate()           );
      XxcsoUtils.debug(txn, "現ルートNoEXTID     ："
                              + registRow.getTrgtRouteNoExtensionId()         );
      XxcsoUtils.debug(txn, "現ルート最終更新日  ："
                              + registRow.getTrgtRouteNoLastUpdDate()         );
      XxcsoUtils.debug(txn, "新ルートNo          ："
                              + registRow.getNextRouteNo()                    );
      XxcsoUtils.debug(txn, "新ルートNo適用開始日："
                              + registRow.getNextRouteNoStartDate()           );
      XxcsoUtils.debug(txn, "新ルートNoEXTID     ："
                              + registRow.getNextRouteNoExtensionId()         );
      XxcsoUtils.debug(txn, "新ルートNo最終更新日："
                              + registRow.getNextRouteNoLastUpdDate()         );
      XxcsoUtils.debug(txn, "現担当              ："
                              + registRow.getTrgtResource()                   );
      XxcsoUtils.debug(txn, "現担当適用開始日    ："
                              + registRow.getTrgtResourceStartDate()          );
      XxcsoUtils.debug(txn, "現担当EXTID         ："
                              + registRow.getTrgtResourceExtensionId()        );
      XxcsoUtils.debug(txn, "現担当最終更新日    ："
                              + registRow.getTrgtResourceLastUpdDate()        );
      XxcsoUtils.debug(txn, "新担当              ："
                              + registRow.getNextResource()                   );
      XxcsoUtils.debug(txn, "新担当適用開始日    ："
                              + registRow.getNextResourceStartDate()          );
      XxcsoUtils.debug(txn, "新担当EXTID         ："
                              + registRow.getNextResourceExtensionId()        );
      XxcsoUtils.debug(txn, "新担当最終更新日    ："
                              + registRow.getNextResourceLastUpdDate()        );
      XxcsoUtils.debug(txn, "READONLY            ："
                              + registRow.getAccountNumberReadOnly()          );
      XxcsoUtils.debug(txn, "ISRSVFLG            ："
                              + registRow.getIsRsvFlg()                       );
// 2010-03-23 [E_本稼動_01942] Add Start
      XxcsoUtils.debug(txn, "SALEBASECODE        ："
                              + registRow.getSaleBaseCode()                   );
      XxcsoUtils.debug(txn, "RSVSALEBASECODE     ："
                              + registRow.getRsvSaleBaseCode()                );
      XxcsoUtils.debug(txn, "RSVSALEBASEACTDATE  ："
                              + registRow.getRsvSaleBaseActDate()             );
// 2010-03-23 [E_本稼動_01942] Add End
// 2015-09-08 [E_本稼動_13307] Add Start
      XxcsoUtils.debug(txn, "DATATYPE            ："
                              + registRow.getCustomerClassCode()              );
// 2015-09-08 [E_本稼動_13307] Add End
// 2009-05-07 [T1_0708] Add Start
      byte rowState = registRow.getXxcsoRtnRsrcVEO().getEntityState();
      if ( rowState == OAPlsqlEntityImpl.STATUS_MODIFIED )
      {
// 2009-05-07 [T1_0708] Add End
// 2010-03-23 [E_本稼動_01942] Add Start
//      //画面項目「新担当」同一拠点内存在チェック
//      if ( registRow.getNextResource() != null
//        && ! registRow.getNextResource().equals("")
//        && registRow.getAccountNumber() != null
//        && ! registRow.getAccountNumber().equals("") )
//      {
//        if ( ! chkExistEmployee( txn, registRow.getNextResource(), baseCode ) )
//        {
//          OAException error
//            = XxcsoMessage.createErrorMessage(
//                XxcsoConstants.APP_XXCSO1_00422,
//                XxcsoConstants.TOKEN_INDEX,
//                String.valueOf(index)
//              );
//          errorList.add(error);
//        }
//      }
// 2010-03-23 [E_本稼動_01942] Add End

// 2015-09-08 [E_本稼動_13307] Del Start
//        //画面項目「新ルートNo」妥当性チェック
//        if ( registRow.getNextRouteNo() != null
//          && ! registRow.getNextRouteNo().equals("")
//          && registRow.getAccountNumber() != null
//          && ! registRow.getAccountNumber().equals("") )
//        {
//          if ( ! chkRouteNo( txn , registRow.getNextRouteNo() ) )
//          {
//            OAException error
//              = XxcsoMessage.createErrorMessage(
//                  XxcsoConstants.APP_XXCSO1_00514,
//                  XxcsoConstants.TOKEN_INDEX,
//                  String.valueOf(index)
//                );
//            errorList.add(error);
//          }
//        }
// 2015-09-08 [E_本稼動_13307] Del End
      //画面項目「新担当」「新ルートNo」に入力値が存在する顧客コードを取得
      if ( ( registRow.getNextResource() != null
        && ! registRow.getNextResource().equals("") )
        || registRow.getNextRouteNo() != null
        && ! registRow.getNextRouteNo().equals("") )
      {
        //画面項目「顧客コード」同一存在チェック
        for ( int i = 0 ; i < coAccountList.size() ; i++ )
        {
          if ( coAccountList.get(i) != null
            && !coAccountList.get(i).equals("")
            && coAccountList.get(i).equals( registRow.getAccountNumber() ) )
          {
            OAException error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00515,
                  XxcsoConstants.TOKEN_INDEX,
                  String.valueOf(index)
                );
            errorList.add(error);
            isSameErr = true;
            continue;
          }
        }
        if ( !isSameErr )
        {
          coAccountList.add(registRow.getAccountNumber());
        }
        isSameErr = false;
      }
// 2010-03-23 [E_本稼動_01942] Add Start
//      //予約売上拠点が自拠点の場合
//      if ( ! isRsvAccount
//        && registRow.getAccountNumber() != null
//        && ! registRow.getAccountNumber().equals("")
//        && registRow.getIsRsvFlg() != null
//        && registRow.getIsRsvFlg().equals(
//             XxcsoRtnRsrcBulkUpdateConstants.BOOL_ISRSV)
//        && ( ( registRow.getNextResource() != null
//            && ! registRow.getNextResource().equals("") )
//            || registRow.getNextRouteNo() != null
//            && ! registRow.getNextRouteNo().equals("")) )
//      {
//        isRsvAccount = true;
//      }
// 2010-03-23 [E_本稼動_01942] Add End
// 2009-05-07 [T1_0708] Add Start
      }
// 2009-05-07 [T1_0708] Add End

// 2010-03-23 [E_本稼動_01942] Add Start
      if ( rowState == OAPlsqlEntityImpl.STATUS_MODIFIED ||
           rowState == OAPlsqlEntityImpl.STATUS_NEW )
      {
// 2015-09-08 [E_本稼動_13307] Add Start
        //売掛管理先顧客以外
        if ( ! XxcsoRtnRsrcBulkUpdateConstants.CUSTOMER_CLASS_14.equals(registRow.getCustomerClassCode()) )
        {
          //画面項目「新ルートNo」妥当性チェック
          if ( registRow.getNextRouteNo() != null
            && ! registRow.getNextRouteNo().equals("")
            && registRow.getAccountNumber() != null
            && ! registRow.getAccountNumber().equals("") )
          {
            if ( ! chkRouteNo( txn , registRow.getNextRouteNo() ) )
            {
              OAException error
                = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00514,
                    XxcsoConstants.TOKEN_INDEX,
                    String.valueOf(index)
                  );
              errorList.add(error);
            }
          }
// 2015-09-08 [E_本稼動_13307] Add End
          //売上拠点チェック
          if (initRow.getReflectMethod() != null && ! "".equals(initRow.getReflectMethod())
             )
          {
            //「反映方法」即時反映の場合
            if (initRow.getReflectMethod().equals(XxcsoRtnRsrcBulkUpdateConstants.REFLECT_TRGT))
            {
              // 売上拠点チェック
              if ( registRow.getAccountNumber() != null
                && ! registRow.getAccountNumber().equals("")
                && ( ( registRow.getNextResource() != null
                    && ! registRow.getNextResource().equals("") )
                    || registRow.getNextRouteNo() != null
                    && ! registRow.getNextRouteNo().equals("")) )
              {
                if (!(chkExistBaseCode(txn, baseCode ,registRow.getSaleBaseCode())
                     )
                   )
                {
                  OAException error
                    = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00603,
                        XxcsoConstants.TOKEN_INDEX,
                        String.valueOf(index)
                      );
                  errorList.add(error);
                }
              }
              //画面項目「新担当」同一拠点内存在チェック
              if ( registRow.getNextResource() != null
                && ! registRow.getNextResource().equals("")
                && registRow.getAccountNumber() != null
                && ! registRow.getAccountNumber().equals("") )
              {
                if ( ! chkExistEmployee( txn, registRow.getNextResource(), initRow.getCurrentDate(), baseCode ) )
                {
                  OAException error
                    = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00422,
                        XxcsoConstants.TOKEN_INDEX,
                        String.valueOf(index)
                      );
                  errorList.add(error);
                }
              }
            }
            //「反映方法」予約反映の場合
            else
            {
              // 売上拠点、予約売上拠点チェックの場合
              if ( registRow.getAccountNumber() != null
                && ! registRow.getAccountNumber().equals("")
                && ( ( registRow.getNextResource() != null
                    && ! registRow.getNextResource().equals("") )
                    || registRow.getNextRouteNo() != null
                    && ! registRow.getNextRouteNo().equals("")) )
              {
                if (!(chkExistRcvBaseCode (txn, 
                                           baseCode ,
                                           initRow.getNextDate(),
                                           registRow.getSaleBaseCode(),
                                           registRow.getRsvSaleBaseCode(),
                                           registRow.getRsvSaleBaseActDate()
                                          )
                     )
                   )
                {
                  OAException error
                    = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00603,
                        XxcsoConstants.TOKEN_INDEX,
                        String.valueOf(index)
                      );
                  errorList.add(error);
                }
              }
              //画面項目「新担当」同一拠点内存在チェック
              if ( registRow.getNextResource() != null
                && ! registRow.getNextResource().equals("")
                && registRow.getAccountNumber() != null
                && ! registRow.getAccountNumber().equals("") )
              {
                if ( ! chkExistEmployee( txn, registRow.getNextResource() , initRow.getNextDate() , baseCode ) )
                {
                  OAException error
                    = XxcsoMessage.createErrorMessage(
                        XxcsoConstants.APP_XXCSO1_00422,
                        XxcsoConstants.TOKEN_INDEX,
                        String.valueOf(index)
                      );
                  errorList.add(error);
                }
              }
            }
          }
// 2015-09-08 [E_本稼動_13307] Add Start
        }
        else
        {
          if (initRow.getReflectMethod() != null && ! "".equals(initRow.getReflectMethod())
             )
          {
            //予約反映の場合エラー
            if ( initRow.getReflectMethod().equals(XxcsoRtnRsrcBulkUpdateConstants.REFLECT_RSV) )
            {
              OAException error
                      = XxcsoMessage.createErrorMessage(
                          XxcsoConstants.APP_XXCSO1_00790,
                          XxcsoConstants.TOKEN_INDEX,
                          String.valueOf(index)
                        );
              errorList.add(error);
            }
            //画面項目「新ルートNo」が設定されている場合エラー
            if ( registRow.getNextRouteNo() != null
              && ! registRow.getNextRouteNo().equals("")
              && registRow.getAccountNumber() != null
              && ! registRow.getAccountNumber().equals("") )
            {
              OAException error
                = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00789,
                    XxcsoConstants.TOKEN_INDEX,
                    String.valueOf(index)
                  );
              errorList.add(error);
            }
            //入金拠点チェック
            if ( ! chkExistReceivableBaseCode( txn, registRow.getAccountNumber() , baseCode ) )
            {
              OAException error
                = XxcsoMessage.createErrorMessage(
                    XxcsoConstants.APP_XXCSO1_00788,
                    XxcsoConstants.TOKEN_INDEX,
                    String.valueOf(index)
                  );
              errorList.add(error);
            }
            //画面項目「新担当」同一拠点内存在チェック
            if ( registRow.getNextResource() != null
              && ! registRow.getNextResource().equals("")
              && registRow.getAccountNumber() != null
              && ! registRow.getAccountNumber().equals("") )
            {
              if ( ! chkExistEmployee( txn, registRow.getNextResource() , initRow.getNextDate() , baseCode ) )
              {
                OAException error
                  = XxcsoMessage.createErrorMessage(
                      XxcsoConstants.APP_XXCSO1_00422,
                      XxcsoConstants.TOKEN_INDEX,
                      String.valueOf(index)
                    );
                errorList.add(error);
              }
            }
          }
        }
// 2015-09-08 [E_本稼動_13307] Add End
      }
// 2010-03-23 [E_本稼動_01942] Add End
      /* 20090402_abe_T1_0125 START*/
      //追加ボタンで未入力の場合は行を削除
      if ( ((( registRow.getNextResource() == null)
        || registRow.getNextResource().equals(""))
        && ((registRow.getNextRouteNo() == null)
        || registRow.getNextRouteNo().equals(""))
        && (registRow.getAccountNumberReadOnly().equals(Boolean.FALSE) ))
        /* 20090819_abe_0001123 START*/
        || ((registRow.getAccountNumber() == null)
          || registRow.getAccountNumber().equals(""))
        /* 20090819_abe_0001123 END*/
        )
      {
        registRow.remove();
      }
      /* 20090402_abe_T1_0125 END*/
      //次行に移行
      registRow = (XxcsoRtnRsrcFullVORowImpl)registVo.next();
    }

    //画面項目「反映方法」選択チェック
    String reflectMethod = initRow.getReflectMethod();
    XxcsoUtils.debug(txn, "反映方法 = " + reflectMethod);

    if ( reflectMethod == null || "".equals(reflectMethod) )
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00423,
            XxcsoConstants.TOKEN_COLUMN,
            XxcsoRtnRsrcBulkUpdateConstants.TOKEN_VALUE_REFLECTMETHOD
          );
      errorList.add(error);
    }
    
// 2010-03-23 [E_本稼動_01942] Add Start
//    //画面項目「反映方法」即時反映時予約売上拠点存在チェック
//    if ( isRsvAccount
//      && initRow.getReflectMethod() != null
//      && initRow.getReflectMethod().equals(
//           XxcsoRtnRsrcBulkUpdateConstants.REFLECT_TRGT) )
//    {
//      OAException error
//        = XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00475
//          );
//      errorList.add(error);
//    }
// 2010-03-23 [E_本稼動_01942] Add End
    
    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 担当営業員拠点内存在チェック
   * @param txn         OADBTransactionインスタンス
   * @param employeeNo  従業員番号
   * @param baseCodeDate 対象拠点日付
   * @param baseCode    拠点コード
   * @return boolean    TRUE:存在する FALSE:存在しない
   *****************************************************************************
   */
  private boolean chkExistEmployee(
    OADBTransaction txn
   ,String employeeNo
// 2010-03-23 [E_本稼動_01942] Add Start
   ,Date   baseCodeDate
// 2010-03-23 [E_本稼動_01942] Add End
   ,String baseCode
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    XxcsoRtnRsrcBulkUpdateEmployeeVOImpl empVo
      = getXxcsoRtnRsrcBulkUpdateEmployeeVO();
    if ( empVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateEmployeeVO"
        );
    }

    empVo.initQuery(
      employeeNo
// 2010-03-23 [E_本稼動_01942] Add Start
     ,baseCodeDate
// 2010-03-23 [E_本稼動_01942] Add End
     ,baseCode
    );

    //引数の従業員番号がログインユーザの同一拠点内に存在する場合
    if ( empVo.getRowCount() != 0 )
    {
      return true;
    }

    XxcsoUtils.debug(txn, "[END]");

    return false;
  }

  /*****************************************************************************
   * ルートNo妥当性チェック
   * @param txn         OADBTransactionインスタンス
   * @param routeNo     チェック対象ルートNo
   * @return boolean    TRUE:妥当 FALSE:非妥当
   *****************************************************************************
   */
  private boolean chkRouteNo(
    OADBTransaction txn
   ,String routeNo
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    OracleCallableStatement stmt = null;

    try
    {
      StringBuffer sql = new StringBuffer(100);
      sql.append("BEGIN");
      sql.append("  xxcso_route_common_pkg.validate_route_no_p(");
      sql.append("     iv_route_number   => :1");
      sql.append("    ,ov_retcode        => :2");
      sql.append("    ,ov_error_reason   => :3");
      sql.append("  );");
      sql.append("END;");

      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.setString(1,  routeNo);
      stmt.registerOutParameter(2, OracleTypes.VARCHAR);
      stmt.registerOutParameter(3, OracleTypes.VARCHAR);
      
      XxcsoUtils.debug(txn, "execute stored start");
      stmt.execute();
      XxcsoUtils.debug(txn, "execute stored end");

      String retCode     = stmt.getString(2);
      String errMsg      = stmt.getString(3);

      XxcsoUtils.debug(txn, "retCode = " + retCode);
      XxcsoUtils.debug(txn, "errMsg = " + errMsg);

      if ( "0".equals( retCode ) )
      {
        return true;
      }
    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle
         ,XxcsoRtnRsrcBulkUpdateConstants.TOKEN_VALUE_ROUTENO
        );
    }
    finally
    {
      try
      {
        if ( stmt != null )
        {
          stmt.close();
        }
      }
      catch ( SQLException sqle )
      {
        XxcsoUtils.unexpected(txn, sqle);
      }
    }
    XxcsoUtils.debug(txn, "[END]");
    return false;
  }


// 2010-03-23 [E_本稼動_01942] Add Start
  /*****************************************************************************
   * 売上拠点チェック
   * @param txn           OADBTransactionインスタンス
   * @param baseCode      拠点コード
   * @param salebaseCode  売上拠点コード
   * @return boolean      TRUE:正常 FALSE:異常
   *****************************************************************************
   */
  private boolean chkExistBaseCode(
    OADBTransaction txn
   ,String baseCode
   ,String salebaseCode
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    if (salebaseCode == null )
    {
      return true;
    }

    if (baseCode.equals(salebaseCode) )
    {
      return true;
    }

    XxcsoUtils.debug(txn, "[END]");

    return false;
  }
  /*****************************************************************************
   * 予約売上拠点チェック
   * @param txn              OADBTransactionインスタンス
   * @param baseCode         拠点コード
   * @param nextDate         翌月１日
   * @param salebaseCode     売上拠点コード
   * @param rcvsalebaseCode  予約売上拠点コード
   * @param rcvsaleActDate   予約売上拠点開始日
   * @return boolean         TRUE:正常 FALSE:異常
   *****************************************************************************
   */
  private boolean chkExistRcvBaseCode(
    OADBTransaction txn
   ,String baseCode
   ,Date   nextDate
   ,String salebaseCode
   ,String rcvsalebaseCode
   ,Date   rcvsaleActDate
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    // 売上拠点コードがない場合
    if ((salebaseCode == null || "".equals(salebaseCode)) &&
        (rcvsalebaseCode == null || "".equals(rcvsalebaseCode)) 
       )
    {
      return true;
    }

    // 売上拠点コードの場合
    if (salebaseCode != null && ! "".equals(salebaseCode))
    {
      if (baseCode.equals(salebaseCode) )
      {
        if (rcvsaleActDate == null || "".equals(rcvsaleActDate))
        {
          return true;
        }
        if ( 0 > nextDate.dateValue().compareTo(rcvsaleActDate.dateValue()) )
        {
          return true;
        }
      }
    }
    // 予約売上拠点コードの場合
    if (rcvsalebaseCode != null && ! "".equals(rcvsalebaseCode))
    {
      if (baseCode.equals(rcvsalebaseCode) )
      {
        if (rcvsaleActDate != null && ! "".equals(rcvsaleActDate))
        {
          if (0 <= nextDate.dateValue().compareTo(rcvsaleActDate.dateValue()) )
          {
            return true;
          }
        }
      }
    }

    XxcsoUtils.debug(txn, "[END]");

    return false;
  }
  
// 2010-03-23 [E_本稼動_01942] Add End

// 2015-09-08 [E_本稼動_13307] Add Start
  /*****************************************************************************
   * 入金拠点チェック
   * @param txn         OADBTransactionインスタンス
   * @param AccountNumber    顧客コード
   * @param baseCode         拠点コード
   * @return boolean         TRUE:存在する FALSE:存在しない
   *****************************************************************************
   */
  private boolean chkExistReceivableBaseCode(
    OADBTransaction txn
   ,String AccountNumber
   ,String baseCode
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    XxcsoRtnRsrcBulkUpdateReceivableVOImpl recVo
      = getXxcsoRtnRsrcBulkUpdateReceivableVO1();
    if ( recVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateReceivableVO"
        );
    }

    recVo.initQuery(
      AccountNumber
     ,baseCode
    );

    //引数の拠点と顧客の入金拠点が同じ場合
    if ( recVo.getRowCount() != 0 )
    {
      return true;
    }

    XxcsoUtils.debug(txn, "[END]");

    return false;
  }
// 2015-09-08 [E_本稼動_13307] Add End

  /*****************************************************************************
   * 適用ボタン押下後再検索処理
   *****************************************************************************
   */
  private void reSearch()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    XxcsoRtnRsrcBulkUpdateInitVOImpl initVo
      = getXxcsoRtnRsrcBulkUpdateInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateInitVO1"
        );
    }

    XxcsoRtnRsrcBulkUpdateSumVOImpl sumVo
      = getXxcsoRtnRsrcBulkUpdateSumVO1();
    if ( sumVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateSumVO1"
        );
    }

    XxcsoRtnRsrcFullVOImpl registVo
      = getXxcsoRtnRsrcFullVO1();
    if ( registVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcFullVO1"
        );
    }
    
    //////////////////////////////////////
    // 各行を取得
    //////////////////////////////////////
    XxcsoRtnRsrcBulkUpdateInitVORowImpl initRow
      = (XxcsoRtnRsrcBulkUpdateInitVORowImpl)initVo.first();

    //////////////////////////////////////
    // 検索処理
    //////////////////////////////////////
    sumVo.initQuery(
      initRow.getEmployeeNumber()
     ,initRow.getFullName()
     ,initRow.getRouteNo()
// 2010-03-23 [E_本稼動_01942] Add Start
     ,initRow.getBaseCode1()
     ,initRow.getBaseName()
// 2010-03-23 [E_本稼動_01942] Add End
    );
    
    registVo.initQuery(
      initRow.getEmployeeNumber()
     ,initRow.getRouteNo()
// 2010-03-23 [E_本稼動_01942] Add Start
     //,initRow.getBaseCode()
     ,initRow.getBaseCode1()
// 2010-03-23 [E_本稼動_01942] Add End
    );
    
    XxcsoRtnRsrcFullVORowImpl registRow
      = (XxcsoRtnRsrcFullVORowImpl)registVo.first();
    
    if ( registRow != null )
    {
      initRow.setAddCustomerButtonRender(Boolean.TRUE);
      while ( registRow != null )
      {
        registRow.setAccountNumberReadOnly(Boolean.TRUE);

        registRow = (XxcsoRtnRsrcFullVORowImpl)registVo.next();
      }
    }
    else
    {
      initRow.setAddCustomerButtonRender(Boolean.FALSE);
    }

    //////////////////////////////////////
    // 検索後検証処理
    //////////////////////////////////////
    List list = chkAfterSearch( txn, registVo );

    if ( list.size() > 0 )
    {
      OAException.raiseBundledOAException( list );
    }

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * プロファイル最大表示行数取得処理
   * @param  txn OADBTransactionインスタンス
   * @return プロファイルのVO_MAX_FETCH_SIZEで指定された行数
   *****************************************************************************
   */
  private String getVoMaxFetchSize(OADBTransaction txn)
  {

    String maxSize = txn.getProfile(XxcsoConstants.VO_MAX_FETCH_SIZE);
    if ( maxSize == null || "".equals(maxSize.trim()) )
    {
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoConstants.VO_MAX_FETCH_SIZE
        );
    }

    return maxSize;
  }

// 2010-03-23 [E_本稼動_01942] Add Start

  /*****************************************************************************
   * 各イベント処理の最後に行われる処理です。
   *****************************************************************************
   */
  public void afterProcess()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoRtnRsrcBulkUpdateInitVOImpl initVo
      = getXxcsoRtnRsrcBulkUpdateInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoRtnRsrcBulkUpdateInitVO1"
        );
    }

    //////////////////////////////////////
    // 各行を取得
    //////////////////////////////////////
    XxcsoRtnRsrcBulkUpdateInitVORowImpl initRow
      = (XxcsoRtnRsrcBulkUpdateInitVORowImpl)initVo.first();


    if ( initRow != null )
    {
      if ( initRow.getBaseCode1() != null )
      {
        initRow.setBaseCodeFlag("Y");
      }
      else
      {
        initRow.setBaseCodeFlag("N");
      }
    }

    XxcsoUtils.debug(txn, "[END]");
  }

// 2010-03-23 [E_本稼動_01942] Add End

  /**
   * 
   * Container's getter for XxcsoRtnRsrcBulkUpdateInitVO1
   */
  public XxcsoRtnRsrcBulkUpdateInitVOImpl getXxcsoRtnRsrcBulkUpdateInitVO1()
  {
    return (XxcsoRtnRsrcBulkUpdateInitVOImpl)findViewObject("XxcsoRtnRsrcBulkUpdateInitVO1");
  }

  /**
   * 
   * Container's getter for XxcsoRtnRsrcBulkUpdateSumVO1
   */
  public XxcsoRtnRsrcBulkUpdateSumVOImpl getXxcsoRtnRsrcBulkUpdateSumVO1()
  {
    return (XxcsoRtnRsrcBulkUpdateSumVOImpl)findViewObject("XxcsoRtnRsrcBulkUpdateSumVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso019009j.server", "XxcsoRtnRsrcBulkUpdateAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoRtnRsrcFullVO1
   */
  public XxcsoRtnRsrcFullVOImpl getXxcsoRtnRsrcFullVO1()
  {
    return (XxcsoRtnRsrcFullVOImpl)findViewObject("XxcsoRtnRsrcFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoReflectMethodListVO
   */
  public XxcsoLookupListVOImpl getXxcsoReflectMethodListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoReflectMethodListVO");
  }

  /**
   * 
   * Container's getter for XxcsoRtnRsrcBulkUpdateEmployeeVO
   */
  public XxcsoRtnRsrcBulkUpdateEmployeeVOImpl getXxcsoRtnRsrcBulkUpdateEmployeeVO()
  {
    return (XxcsoRtnRsrcBulkUpdateEmployeeVOImpl)findViewObject("XxcsoRtnRsrcBulkUpdateEmployeeVO");
  }

  /**
   * 
   * Container's getter for XxcsoRtnRsrcBulkUpdateReceivableVO1
   */
  public XxcsoRtnRsrcBulkUpdateReceivableVOImpl getXxcsoRtnRsrcBulkUpdateReceivableVO1()
  {
    return (XxcsoRtnRsrcBulkUpdateReceivableVOImpl)findViewObject("XxcsoRtnRsrcBulkUpdateReceivableVO1");
  }


}