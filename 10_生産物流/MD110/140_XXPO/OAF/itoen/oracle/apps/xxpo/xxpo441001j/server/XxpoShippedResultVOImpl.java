/*============================================================================
* ファイル名 : XxpoShippedResultVOImpl
* 概要説明   : 出庫実績要約結果ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-24 1.0  山本恭久     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo441001j.server;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnUtility;

import java.util.ArrayList;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
/***************************************************************************
 * 出庫実績要約結果ビューオブジェクトクラスです。
 * @author  ORACLE 山本恭久
 * @version 1.0
 ***************************************************************************
 */
public class XxpoShippedResultVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoShippedResultVOImpl()
  {
  }
    /*****************************************************************************
   * VOの初期化を行います。
   * @param shParams - 検索パラメータ
   ****************************************************************************/
  public void initQuery(
    HashMap shParams
    )
  {
    StringBuffer whereClause = new StringBuffer(1000);  // WHERE句作成用オブジェクト
    ArrayList parameters = new ArrayList();             // バインド変数設定値
    int bindCount = 0;                                  // バインド変数カウント

    // 初期化
    setWhereClauseParams(null);

    // 検索条件取得
    Number orderType    = (Number)shParams.get("orderType");    // 発生区分
    String vendorCode   = (String)shParams.get("vendorCode");   // 取引先
    String shipToCode   = (String)shParams.get("shipToCode");   // 配送先
    String reqNo        = (String)shParams.get("reqNo");        // 依頼No
    String shipToNo     = (String)shParams.get("shipToNo");     // 配送No
    String transStatus  = (String)shParams.get("transStatus");  // ステータス
    String notifStatus  = (String)shParams.get("notifStatus");  // 通知ステータス
    Date shipDateFrom   = (Date)shParams.get("shipDateFrom");   // 出庫日From
    Date shipDateTo     = (Date)shParams.get("shipDateTo");     // 出庫日To
    Date arvlDateFrom   = (Date)shParams.get("arvlDateFrom");   // 入庫日From
    Date arvlDateTo     = (Date)shParams.get("arvlDateTo");     // 入庫日To
    String reqDeptCode  = (String)shParams.get("reqDeptCode");  // 依頼部署
    String instDeptCode = (String)shParams.get("instDeptCode"); // 指示部署
    String shipWhseCode = (String)shParams.get("shipWhseCode"); // 出庫倉庫  

    String exeType      = (String)shParams.get("exeType"); //起動タイプ
    
    // 起動タイプ(必須)
    XxcmnUtility.andAppend(whereClause);
    whereClause.append("exe_type = :" + bindCount++);
    parameters.add(exeType);

    // 発生区分が入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(orderType))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where句生成
      whereClause.append("order_type_id = :" + bindCount++);
      // 検索値をセット
      parameters.add(orderType);      
    }
    // 取引先が入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(vendorCode))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where句生成
      whereClause.append("vendor_code = :" + bindCount++);
      //検索値をセット
      parameters.add(vendorCode);      
    }
    // 配送先が入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(shipToCode))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where句生成
      whereClause.append("ship_to_code = :" + bindCount++);
      //検索値をセット
      parameters.add(shipToCode);      
    }
    // 依頼Noが入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(reqNo))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where句生成
      whereClause.append("request_no = :" + bindCount++);
      //検索値をセット
      parameters.add(reqNo);      
    }
    // 配送Noが入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(shipToNo))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where句生成
      whereClause.append("ship_to_no = :" + bindCount++);
      //検索値をセット
      parameters.add(shipToNo);      
    }
    // ステータスが入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(transStatus))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where句生成
      whereClause.append("trans_status = :" + bindCount++);
      //検索値をセット
      parameters.add(transStatus);      
    }
    // 通知ステータスが入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(notifStatus))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where句生成
      whereClause.append("notif_status = :" + bindCount++);
      //検索値をセット
      parameters.add(notifStatus);      
    }
    // 出庫日Fromが入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(shipDateFrom))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where句生成
      whereClause.append("shipped_date >= :" + bindCount++);
      //検索値をセット
      parameters.add(shipDateFrom);      
    }
    // 出庫日Toが入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(shipDateTo))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where句生成
      whereClause.append("shipped_date <= :" + bindCount++);
      //検索値をセット
      parameters.add(shipDateTo);      
    }
    // 入庫日Fromが入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(arvlDateFrom))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where句生成
      whereClause.append("arrival_date >= :" + bindCount++);
      //検索値をセット
      parameters.add(arvlDateFrom);      
    }
    // 入庫日Toが入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(arvlDateTo))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where句生成
      whereClause.append("arrival_date <= :" + bindCount++);
      //検索値をセット
      parameters.add(arvlDateTo);      
    }
    // 依頼部署が入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(reqDeptCode))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where句生成
      whereClause.append("req_dept_code = :" + bindCount++);
      //検索値をセット
      parameters.add(reqDeptCode);      
    }
    // 指示部署が入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(instDeptCode))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where句生成
      whereClause.append("inst_dept_code = :" + bindCount++);
      //検索値をセット
      parameters.add(instDeptCode);      
    }
    // 出庫倉庫が入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(shipWhseCode))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where句生成
      whereClause.append("ship_whse_code = :" + bindCount++);
      //検索値をセット
      parameters.add(shipWhseCode);      
    }
    
    // 検索条件をVOにセット
    setWhereClause(whereClause.toString());

    // バインド値が設定されていた場合
    if (bindCount > 0)
    {
      // 検索値配列を取得
      Object[] params = new Object[bindCount];
      params = parameters.toArray();  
      // WHERE句のバインド変数に検索値をセット
      setWhereClauseParams(params);
    }
    // 検索実行
    executeQuery();
  }
}
