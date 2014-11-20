/*============================================================================
* ファイル名 : XxcsoAcctMonthlyPlanFullVOImpl
* 概要説明   : 売上計画(複数顧客)　アプリケーションモジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS朴邦彦    新規作成
* 2009-04-22 1.1  SCS柳平直人  [ST障害T1_0585]画面遷移セキュリティ不正対応
* 2009-06-30 1.2  SCS阿部大輔  [障害0000281]先３ヶ月のチェック修正
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019002j.server;

import itoen.oracle.apps.xxcso.xxcso019002j.poplist.server.XxcsoTargetYearListVOImpl;
import itoen.oracle.apps.xxcso.xxcso019002j.poplist.server.XxcsoTargetMonthListVOImpl;
import itoen.oracle.apps.xxcso.xxcso019002j.util.XxcsoSalesPlanBulkRegistConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoRouteManagementUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoValidateUtils;
// 2009/04/22 [ST障害T1_0585] Del Start
//import itoen.oracle.apps.xxcso.common.util.XxcsoAcctSalesPlansUtils;
// 2009/04/22 [ST障害T1_0585] Del End
// 2009-06-30 [障害0000281] Add Start
import itoen.oracle.apps.xxcso.common.util.XxcsoAcctSalesPlansUtils;
// 2009-06-30 [障害0000281] Add End

import oracle.apps.fnd.framework.OAException;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.server.OAEntityImpl;

import oracle.jbo.domain.Date;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.List;

/*******************************************************************************
 * 売上計画(複数顧客) アプリケーションモジュールクラス
 * @author  SCS朴邦彦
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesPlanBulkRegistAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesPlanBulkRegistAMImpl()
  {
  }

  /*****************************************************************************
   * 初期画面表示の処理を行います。
   * @param mode    画面モード
   *****************************************************************************
   */
  public void initDetails(
    String mode
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");
    
    this.rollback();
    
    XxcsoSalesPlanBulkRegistInitVOImpl initVo = 
      getXxcsoSalesPlanBulkRegistInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.
              createInstanceLostError("XxcsoSalesPlanBulkRegistInitVOImpl");
    }

    if ( ! initVo.isPreparedForExecution() )
    {
      XxcsoUtils.debug(txn, "initVo.executeQuery()");
      initVo.executeQuery();
    }

    XxcsoSalesPlanBulkRegistInitVORowImpl initRow
      = (XxcsoSalesPlanBulkRegistInitVORowImpl)initVo.first();

    if ( XxcsoSalesPlanBulkRegistConstants.MODE_FIRE_ACTION.equals(mode) )
    {
      XxcsoRsrcPlanSummaryVOImpl rsrcSumVo = getXxcsoRsrcPlanSummaryVO1();
      if ( rsrcSumVo == null )
      {
        throw XxcsoMessage.
                createInstanceLostError("XxcsoRsrcPlanSummaryVOImpl");
      }
      XxcsoRsrcPlanSummaryVORowImpl rsrcSumRow
        = (XxcsoRsrcPlanSummaryVORowImpl)rsrcSumVo.first();

      executeQuery(
        rsrcSumRow.getBaseCode()
       ,rsrcSumRow.getEmployeeNumber()
       ,""
       ,rsrcSumRow.getTargetYearMonth().substring(0, 4)
       ,rsrcSumRow.getTargetYearMonth().substring(4, 6)
      );

      initRow.setResultRender(Boolean.TRUE);
    }
    else
    {
      initRow.setResultRender(Boolean.FALSE);
    }

// 2009/04/22 [ST障害T1_0585] Mod Start
//    // ログインユーザが拠点営業員の場合、営業員は選択不可（自身固定）
//    initRow.setReadOnlyFlg(Boolean.FALSE);
//    if ( XxcsoAcctSalesPlansUtils.isSalesPerson( txn ) )
//    {
//      initRow.setReadOnlyFlg(Boolean.TRUE);
//      initRow.setEmployeeNumber(initRow.getMyEmployeeNumber());
//      initRow.setFullName(initRow.getMyFullName());
//    }
    // プロファイルの取得（売上計画セキュリティ）
    String salesPlanSequrity =
      txn.getProfile(
        XxcsoSalesPlanBulkRegistConstants.XXCSO1_SALES_PLAN_SECURITY
      );
    if ( salesPlanSequrity == null || "".equals(salesPlanSequrity.trim()) )
    {
      throw
        XxcsoMessage.createProfileNotFoundError(
          XxcsoSalesPlanBulkRegistConstants.XXCSO1_SALES_PLAN_SECURITY
        );
    }
    initRow.setReadOnlyFlg( Boolean.FALSE );
    if ( XxcsoSalesPlanBulkRegistConstants.SECURITY_REFERENCE.equals(
           salesPlanSequrity)
    )
    {
      // ログインユーザーが担当営業員の場合
      // 営業員入力項目は編集不可・ログインユーザーを設定
      initRow.setReadOnlyFlg( Boolean.TRUE );
      initRow.setEmployeeNumber( initRow.getMyEmployeeNumber() );
      initRow.setFullName(       initRow.getMyFullName()       );
    }
// 2009/04/22 [ST障害T1_0585] Mod End

    XxcsoTargetYearListVOImpl yearListVo = getXxcsoTargetYearListVO1();
    yearListVo.executeQuery();

    XxcsoTargetMonthListVOImpl monthListVo = getXxcsoTargetMonthListVO1();
    monthListVo.executeQuery();
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 進むボタンの処理を行います。
   *****************************************************************************
   */
  public void handleSearchButton()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    if ( getTransaction().isDirty() )
    {
      throw XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00335);
    }
    
    XxcsoSalesPlanBulkRegistInitVOImpl initVo = 
      getXxcsoSalesPlanBulkRegistInitVO1();
    if ( initVo == null )
    {
      throw XxcsoMessage.
        createInstanceLostError("XxcsoSalesPlanBulkRegistInitVOImpl");
    }

    XxcsoSalesPlanBulkRegistInitVORowImpl initRow
      = (XxcsoSalesPlanBulkRegistInitVORowImpl)initVo.first();

    // バリデーション＆テーブル存在チェック
    List errorList = new ArrayList();
    this.validateSearchButton(errorList, initRow);
    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    executeQuery(
      initRow.getBaseCode()
     ,initRow.getEmployeeNumber()
     ,initRow.getFullName()
     ,initRow.getTargetYear()
     ,initRow.getTargetMonth()
    );

    initRow.setResultRender(Boolean.TRUE);
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 適用ボタンの処理を行います。
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

    XxcsoAcctMonthlyPlanFullVOImpl monthlyVo = 
      getXxcsoAcctMonthlyPlanFullVO1();    
    if ( monthlyVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoAcctMonthlyPlanFullVOImpl");
    }

    XxcsoAcctMonthlyPlanFullVORowImpl monthlyRow
      = (XxcsoAcctMonthlyPlanFullVORowImpl)monthlyVo.first();
    
    // バリデーション＆テーブル存在チェック
    List errorList = new ArrayList();
    this.validateMonthlyPlan(errorList, monthlyVo, monthlyRow);
    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    // 正常メッセージ作成
    List msgList   = new ArrayList();
    if ( getMonthlyState( monthlyVo ) )
    {
      OAException msg
        = XxcsoMessage.createConfirmMessage(
            XxcsoConstants.APP_XXCSO1_00001
           ,XxcsoConstants.TOKEN_RECORD
           ,XxcsoConstants.TOKEN_VALUE_ACCT_MONTHLY_PLAN
           ,XxcsoConstants.TOKEN_ACTION
           ,XxcsoConstants.TOKEN_VALUE_SAVE
        );
        
      msgList.add(msg);

      // エンティティ以外項目をセット
      setOtherMonthlyVo( monthlyVo );
    }

    // エンティティオブジェクト実行
    commit();

    XxcsoUtils.debug(txn, "[END]");

    return OAException.getBundledOAException(msgList);
  }

  /*****************************************************************************
   * 取消ボタンの処理を行います。
   *****************************************************************************
   */
  public void handleCancelButton()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    this.rollback();

    XxcsoUtils.debug(txn, "[END]");
  }
  
  /*****************************************************************************
   * ビュー・オブジェクトの検索を行います。
   * @param baseCode        拠点コード
   * @param employeeNumber  従業員番号
   * @param fullName        従業員名
   * @param targetYear      対象年
   * @param targetMonth     対象月
   *****************************************************************************
   */
  private void executeQuery(
    String baseCode
   ,String employeeNumber
   ,String fullName
   ,String targetYear
   ,String targetMonth
  )
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    XxcsoRouteManagementUtils.getInstance().initTransactionBulk(
      getOADBTransaction()
     ,baseCode
     ,employeeNumber
     ,targetYear
     ,targetMonth
    );
    
    XxcsoRsrcPlanSummaryVOImpl rsrcSumVo = getXxcsoRsrcPlanSummaryVO1();
    if ( rsrcSumVo == null )
    {
      throw XxcsoMessage.createInstanceLostError("XxcsoRsrcPlanSummaryVOImpl");
    }
    
    rsrcSumVo.initQuery(
      baseCode
     ,employeeNumber
     ,targetYear + targetMonth
    );

    XxcsoRsrcPlanSummaryVORowImpl rsrcSuRow
      = (XxcsoRsrcPlanSummaryVORowImpl)rsrcSumVo.first();

    // 対象年月が過去の場合、顧客別月別売上計画は編集不可
    rsrcSuRow.setReadOnlyFlg(Boolean.FALSE);
    if ( rsrcSuRow != null )
    {
      if ( "1".equals(rsrcSuRow.getReadonlyValue()) )
      {
        rsrcSuRow.setReadOnlyFlg(Boolean.TRUE);
      }
    }

    XxcsoAcctMonthlyPlanFullVOImpl monthlyVo = 
      getXxcsoAcctMonthlyPlanFullVO1();
    if ( monthlyVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoAcctMonthlyPlanFullVOImpl");
    }

    monthlyVo.initQuery(
      baseCode
     ,targetYear + targetMonth
     ,employeeNumber
    );

    XxcsoAcctMonthlyPlanFullVORowImpl monthlyRow
      = (XxcsoAcctMonthlyPlanFullVORowImpl)monthlyVo.first();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 検索ボタン押下時のバリデーションチェック処理
   * @param errorList  エラーリスト
   * @param initRow    売上計画(複数顧客)検索VO
   *****************************************************************************
   */
  private List validateSearchButton(
    List errorList
   ,XxcsoSalesPlanBulkRegistInitVORowImpl initRow
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // バリデーションチェックを行います。
    XxcsoValidateUtils util = XxcsoValidateUtils.getInstance(txn);

    // 営業員コード
    errorList
      = util.requiredCheck(
          errorList
         ,initRow.getEmployeeNumber()
         ,XxcsoSalesPlanBulkRegistConstants.TOKEN_VALUE_EMPLOYEE_NUMBER
         ,0
        );

    // 対象年
    errorList
      = util.requiredCheck(
          errorList
         ,initRow.getTargetYear()
         ,XxcsoSalesPlanBulkRegistConstants.TOKEN_VALUE_TARGET_YEAR
         ,0
        );
        
    // 対象月
    errorList
      = util.requiredCheck(
          errorList
         ,initRow.getTargetMonth()
         ,XxcsoSalesPlanBulkRegistConstants.TOKEN_VALUE_TARGET_MONTH
         ,0
        );
        
    if ( errorList.size() > 0 )
    {
      return errorList;
    }
    
    // 対象年月≦先２ヶ月であること
    String targetYM = initRow.getTargetYear() + initRow.getTargetMonth();
// 2009-06-30 [障害0000281] Add Start
    //Date nowDate = txn.getCurrentUserDate();
    Date nowDate = XxcsoAcctSalesPlansUtils.getOnlineSysdate(txn);
// 2009-06-30 [障害0000281] Add End    
    String next2YM = 
      nowDate.addMonths(2).toString().substring(0, 4) 
      + nowDate.toString().substring(5, 7);
    if ( next2YM.compareTo(targetYM) < 0 ) 
    {
      OAException error
        = XxcsoMessage.createErrorMessage(
            XxcsoConstants.APP_XXCSO1_00316
          );
      errorList.add(error);
    }

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * 顧客別売上計画のバリデーションチェック処理
   * @param errorList   エラーリスト
   * @param monthlyVo    顧客別売上計画日別VO
   * @param monthlyRow   顧客別売上計画日別行VO
   *****************************************************************************
   */
  private List validateMonthlyPlan(
    List errorList
   ,XxcsoAcctMonthlyPlanFullVOImpl monthlyVo
   ,XxcsoAcctMonthlyPlanFullVORowImpl monthlyRow
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // バリデーションチェックを行います。
    XxcsoValidateUtils utils = XxcsoValidateUtils.getInstance(txn);

    byte monthlyState = OAEntityImpl.STATUS_UNMODIFIED;
    while ( monthlyRow != null )
    {
      byte monthlyRowState
        = monthlyRow.getXxcsoAcctMonthlyPlansVEO().getEntityState();

      if ( monthlyRowState == OAEntityImpl.STATUS_MODIFIED )
      {
        monthlyState = monthlyRowState;

        // 顧客別月別売上計画（対象月）
        errorList
          = utils.checkStringToNumber(
              errorList
             ,monthlyRow.getTargetMonthSalesPlanAmt()
             ,XxcsoSalesPlanBulkRegistConstants.
                TOKEN_VALUE_TRGT_MONTH_SALES_PLAN_AMT +
                  XxcsoConstants.TOKEN_VALUE_SEP_LEFT +
                  XxcsoSalesPlanBulkRegistConstants.TOKEN_VALUE_PARTY_NAME +
                  XxcsoConstants.TOKEN_VALUE_DELIMITER3 +
                  monthlyRow.getPartyName() +
                  XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
             ,0
             ,7
             ,true
             ,false
             ,false
             ,monthlyVo.getCurrentRowIndex() + 1
            );

        // 顧客別月別売上計画（対象翌月）
        errorList
          = utils.checkStringToNumber(
              errorList
             ,monthlyRow.getNextMonthSalesPlanAmt()
             ,XxcsoSalesPlanBulkRegistConstants.
                TOKEN_VALUE_NEXT_MONTH_SALES_PLAN_AMT +
                  XxcsoConstants.TOKEN_VALUE_SEP_LEFT +
                  XxcsoSalesPlanBulkRegistConstants.TOKEN_VALUE_PARTY_NAME +
                  XxcsoConstants.TOKEN_VALUE_DELIMITER3 +
                  monthlyRow.getPartyName() +
                  XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
             ,0
             ,7
             ,true
             ,false
             ,false
             ,monthlyVo.getCurrentRowIndex() + 1
            );

        // 担当営業員（対象翌月）
        if ( monthlyRow.getNextEmployeeNumber() == null ||
             "".equals(monthlyRow.getNextEmployeeNumber()) )
        {
          errorList.add(
            XxcsoMessage.createErrorMessage(
              XxcsoConstants.APP_XXCSO1_00396
             ,XxcsoConstants.TOKEN_ACCOUNT
             ,XxcsoSalesPlanBulkRegistConstants.TOKEN_VALUE_PARTY_NAME +
                XxcsoConstants.TOKEN_VALUE_DELIMITER3 +
                monthlyRow.getPartyName()
            )
          );
        }

        // ルートNo（対象月）
        if ( monthlyRow.getTargetMonthSalesPlanAmt() != null &&
             !"".equals(monthlyRow.getTargetMonthSalesPlanAmt()) )
        {
          if ( monthlyRow.getTargetRouteNumber() == null ||
               "".equals(monthlyRow.getTargetRouteNumber()) )
          {
            errorList.add(
              XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00311
               ,XxcsoConstants.TOKEN_ACCOUNT
               ,XxcsoSalesPlanBulkRegistConstants.TOKEN_VALUE_PARTY_NAME +
                  XxcsoConstants.TOKEN_VALUE_DELIMITER3 +
                  monthlyRow.getPartyName()
              )
            );
          }
        }

        // ルートNo（対象翌月）
        if ( monthlyRow.getNextMonthSalesPlanAmt() != null &&
             !"".equals(monthlyRow.getNextMonthSalesPlanAmt()) )
        {
          if ( monthlyRow.getNextRouteNumber() == null ||
               "".equals(monthlyRow.getNextRouteNumber()) )
          {
            errorList.add(
              XxcsoMessage.createErrorMessage(
                XxcsoConstants.APP_XXCSO1_00311
               ,XxcsoConstants.TOKEN_ACCOUNT
               ,XxcsoSalesPlanBulkRegistConstants.TOKEN_VALUE_PARTY_NAME +
                  XxcsoConstants.TOKEN_VALUE_DELIMITER3 +
                  monthlyRow.getPartyName()
              )
            );
          }
        }
      }
      monthlyRow = (XxcsoAcctMonthlyPlanFullVORowImpl)monthlyVo.next();
    }

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
  }

  /*****************************************************************************
   * 顧客別売上計画の変更有無判定
   * @param monthlyVo    顧客別売上計画VO
   *****************************************************************************
   */
  private boolean getMonthlyState(
    XxcsoAcctMonthlyPlanFullVOImpl monthlyVo
  )
  {
    XxcsoAcctMonthlyPlanFullVORowImpl monthlyRow = 
      (XxcsoAcctMonthlyPlanFullVORowImpl)monthlyVo.first();
    byte monthlyState = OAEntityImpl.STATUS_UNMODIFIED;
    while ( monthlyRow != null )
    {
      byte monthlyRowState
        = monthlyRow.getXxcsoAcctMonthlyPlansVEO().getEntityState();

      if ( monthlyRowState == OAEntityImpl.STATUS_MODIFIED )
      {
        return true;
      }
      monthlyRow = (XxcsoAcctMonthlyPlanFullVORowImpl)monthlyVo.next();
    }

    return false;
  }

  /*****************************************************************************
   * 顧客別売上計画のEntity以外の項目をセット
   * @param monthlyVo    顧客別売上計画VO
   *****************************************************************************
   */
  private void setOtherMonthlyVo(
    XxcsoAcctMonthlyPlanFullVOImpl monthlyVo
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoAcctMonthlyPlanFullVORowImpl monthlyRow = 
      (XxcsoAcctMonthlyPlanFullVORowImpl)monthlyVo.first();
    while ( monthlyRow != null )
    {
      byte monthlyRowState
        = monthlyRow.getXxcsoAcctMonthlyPlansVEO().getEntityState();

      if ( monthlyRowState == OAEntityImpl.STATUS_MODIFIED )
      {
        // 按分処理対象フラグ
        monthlyRow.getXxcsoAcctMonthlyPlansVEO().
          setDistributeFlg(
            "1"
          );

        // パーティID
        monthlyRow.getXxcsoAcctMonthlyPlansVEO().
          setPartyId(
            monthlyRow.getPartyId()
          );

        // 訪問対象区分
        monthlyRow.getXxcsoAcctMonthlyPlansVEO().
          setVistTargetDiv(
            monthlyRow.getVistTargetDiv()
          );

        // ルートNo（対象月）
        monthlyRow.getXxcsoAcctMonthlyPlansVEO().
          setTargetRouteNumber(
            monthlyRow.getTargetRouteNumber()
          );

        // ルートNo（対象翌月）
        monthlyRow.getXxcsoAcctMonthlyPlansVEO().
          setNextRouteNumber(
            monthlyRow.getNextRouteNumber()
          );

      }
      monthlyRow = (XxcsoAcctMonthlyPlanFullVORowImpl)monthlyVo.next();
    }

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * トランザクションコミット
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
   * トランザクションロールバック
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
  
  /**
   * 
   * Container's getter for XxcsoRsrcPlanSummaryVO1
   */
  public XxcsoRsrcPlanSummaryVOImpl getXxcsoRsrcPlanSummaryVO1()
  {
    return (XxcsoRsrcPlanSummaryVOImpl)findViewObject("XxcsoRsrcPlanSummaryVO1");
  }

  /**
   * 
   * Container's getter for XxcsoAcctMonthlyPlanFullVO1
   */
  public XxcsoAcctMonthlyPlanFullVOImpl getXxcsoAcctMonthlyPlanFullVO1()
  {
    return (XxcsoAcctMonthlyPlanFullVOImpl)findViewObject("XxcsoAcctMonthlyPlanFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSalesPlanBulkRegistInitVO1
   */
  public XxcsoSalesPlanBulkRegistInitVOImpl getXxcsoSalesPlanBulkRegistInitVO1()
  {
    return (XxcsoSalesPlanBulkRegistInitVOImpl)findViewObject("XxcsoSalesPlanBulkRegistInitVO1");
  }

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso019002j.server", "XxcsoSalesPlanBulkRegistAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoTargetYearListVO1
   */
  public XxcsoTargetYearListVOImpl getXxcsoTargetYearListVO1()
  {
    return (XxcsoTargetYearListVOImpl)findViewObject("XxcsoTargetYearListVO1");
  }

  /**
   * 
   * Container's getter for XxcsoTargetMonthListVO1
   */
  public XxcsoTargetMonthListVOImpl getXxcsoTargetMonthListVO1()
  {
    return (XxcsoTargetMonthListVOImpl)findViewObject("XxcsoTargetMonthListVO1");
  }
}