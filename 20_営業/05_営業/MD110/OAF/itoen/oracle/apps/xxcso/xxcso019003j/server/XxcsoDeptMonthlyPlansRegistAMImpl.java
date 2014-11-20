/*============================================================================
* ファイル名 : XxcsoDeptMonthlyPlansRegistAMImpl
* 概要説明   : 売上計画の選択入力画面アプリケーション・モジュールクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS及川領  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019003j.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;

import oracle.apps.fnd.framework.server.OADBTransaction;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoRouteManagementUtils;
import itoen.oracle.apps.xxcso.xxcso019003j.util.XxcsoDeptMonthlyPlansConstants;
import com.sun.java.util.collections.HashMap;
import oracle.apps.fnd.framework.OAException;
import com.sun.java.util.collections.List;
import com.sun.java.util.collections.ArrayList;
/*******************************************************************************
 * 売上計画の選択入力画面のアプリケーション・モジュールクラス
 * @author  SCS及川領
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoDeptMonthlyPlansRegistAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoDeptMonthlyPlansRegistAMImpl()
  {
  }

  /*****************************************************************************
   * 初期化処理
   *****************************************************************************
   */
  public void initDetails()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // トランザクションを初期化
    rollback();

    ////////////////
    //インスタンス取得
    ////////////////
    XxcsoDeptMonthlyPlansInitVOImpl initVo = getXxcsoDeptMonthlyPlansInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoDeptMonthlyPlansInitVO1");
    }

    XxcsoDeptMonthlyPlansFullVOImpl deptVo
      = getXxcsoDeptMonthlyPlansFullVO1();

    if ( deptVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoDeptMonthlyPlansFullVO1");
    }

    initVo.executeQuery();

    XxcsoDeptMonthlyPlansInitVORowImpl initRow
      = (XxcsoDeptMonthlyPlansInitVORowImpl)initVo.first();

    deptVo.initQuery(initRow.getWorkBaseCode());

    XxcsoDeptMonthlyPlansFullVORowImpl deptRow
      = (XxcsoDeptMonthlyPlansFullVORowImpl)deptVo.first();

    int index = 0;
    
    while ( deptRow != null )
    {
      index++;

      // タイトルの作成
      if ( index == 1 )
      {
        deptRow.setTitle(XxcsoDeptMonthlyPlansConstants.TITLE_THIS_MONTH);
        deptRow.setYearAttrReadOnly(Boolean.TRUE);
        deptRow.setMonthAttrReadOnly(Boolean.TRUE);
      }
      else
      {
        deptRow.setTitle(XxcsoDeptMonthlyPlansConstants.TITLE_NEXT_MONTH);
        deptRow.setYearAttrReadOnly(Boolean.FALSE);
        deptRow.setMonthAttrReadOnly(Boolean.FALSE);
      }

      // 計画の設定
      if ( deptRow.getSalesPlanRelDiv() == null )
      {
        deptRow.setSalesPlanRelDiv(
          XxcsoDeptMonthlyPlansConstants.DEF_SALES_PLAN_REL_DIV);
      }

      deptRow = (XxcsoDeptMonthlyPlansFullVORowImpl)deptVo.next();
    }

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ポップリスト初期化処理
   *****************************************************************************
   */
  public void initPoplist()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    // *************************
    // *****poplistの生成*******
    // *************************
    // *****年
    XxcsoYearListVOImpl ylistVo = getXxcsoYearListVO1();
    if ( ylistVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoYearListVO1");
    }

    // *****月
    XxcsoMonthListVOImpl mlistVo = getXxcsoMonthListVO1();
    if ( mlistVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoMonthListVO1");
    }

    // *****計画
    XxcsoLookupListVOImpl salesPlanLookupVo
      = getXxcsoSalesPlanRelDivLookupVO();
    if (salesPlanLookupVo == null)
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoSalesPlanRelDivLookupVO");
    }
    // lookupの初期化
    salesPlanLookupVo.initQuery("XXCSO1_SALS_RELEASE_DIVISION", "1");

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 適用ボタン押下時処理
   * @return HashMap 正常終了メッセージ,URLパラメータ
   *****************************************************************************
   */
  public HashMap handleApplicableButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    if ( ! getTransaction().isDirty() )
    {
      throw XxcsoMessage.createNotChangedMessage();
    }

    List errorList = new ArrayList();
    // 日付チェック
    errorList = validateDate(errorList);

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    // 保存処理を実行します。
    commit();

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoDeptMonthlyPlansConstants.TOKEN_VALUE_SALES_PLANS
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoConstants.TOKEN_VALUE_REGIST
        );

    HashMap returnValue = new HashMap(1);
    returnValue.put(
      XxcsoDeptMonthlyPlansConstants.RETURN_PARAM_MSG
     ,msg
    );

    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
  }

  /*****************************************************************************
   * 日付チェック処理
   * @param errorList エラーリスト
   *****************************************************************************
   */
  private List validateDate(
    List errorList
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    ////////////////
    //インスタンス取得
    ////////////////
    XxcsoDeptMonthlyPlansFullVOImpl deptVo
      = getXxcsoDeptMonthlyPlansFullVO1();

    if ( deptVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoDeptMonthlyPlansFullVO1");
    }

    XxcsoDeptMonthlyPlansFullVORowImpl deptRow
      = (XxcsoDeptMonthlyPlansFullVORowImpl)deptVo.first();

    // パラメータ
    HashMap returnValue = new HashMap(1);

    int index = 0;
    String curent_date = null;
    String next_date   = null;

    while ( deptRow != null )
    {
      index++;

      // 日付チェック
      if ( index == 1 )
      {
        curent_date = deptRow.getTargetYear() + deptRow.getTargetMonth();
      }
      else
      {
        next_date = deptRow.getTargetYear() + deptRow.getTargetMonth();
      }

      deptRow = (XxcsoDeptMonthlyPlansFullVORowImpl)deptVo.next();
    }

    if ( Integer.parseInt(curent_date) >= Integer.parseInt(next_date) )
    {
      // 未来月要選択
      OAException error
        = XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00044
         ,XxcsoConstants.TOKEN_ENTRY
         ,XxcsoDeptMonthlyPlansConstants.TOKEN_VALUE_MONTH
        );
      errorList.add(error);
    }

    XxcsoUtils.debug(txn, "[END]");

    return errorList;
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
      // ロールバックを行います。
      getTransaction().rollback();
    }

    XxcsoUtils.debug(txn, "[END]");

  }



  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso019003j.server", "XxcsoDeptMonthlyPlansRegistAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoSalesPlanRelDivLookupVO
   */
  public XxcsoLookupListVOImpl getXxcsoSalesPlanRelDivLookupVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoSalesPlanRelDivLookupVO");
  }

  /**
   * 
   * Container's getter for XxcsoDeptMonthlyPlansInitVO1
   */
  public XxcsoDeptMonthlyPlansInitVOImpl getXxcsoDeptMonthlyPlansInitVO1()
  {
    return (XxcsoDeptMonthlyPlansInitVOImpl)findViewObject("XxcsoDeptMonthlyPlansInitVO1");
  }


  /**
   * 
   * Container's getter for XxcsoYearListVO1
   */
  public XxcsoYearListVOImpl getXxcsoYearListVO1()
  {
    return (XxcsoYearListVOImpl)findViewObject("XxcsoYearListVO1");
  }

  /**
   * 
   * Container's getter for XxcsoMonthListVO1
   */
  public XxcsoMonthListVOImpl getXxcsoMonthListVO1()
  {
    return (XxcsoMonthListVOImpl)findViewObject("XxcsoMonthListVO1");
  }

  /**
   * 
   * Container's getter for XxcsoDeptMonthlyPlansFullVO1
   */
  public XxcsoDeptMonthlyPlansFullVOImpl getXxcsoDeptMonthlyPlansFullVO1()
  {
    return (XxcsoDeptMonthlyPlansFullVOImpl)findViewObject("XxcsoDeptMonthlyPlansFullVO1");
  }




}