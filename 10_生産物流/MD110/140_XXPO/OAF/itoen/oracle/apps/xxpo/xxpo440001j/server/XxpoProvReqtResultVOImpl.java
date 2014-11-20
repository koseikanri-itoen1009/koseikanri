/*============================================================================
* ファイル名 : XxpoProvReqtResultVOImpl
* 概要説明   : 支給指示要約結果ビューオブジェクト
* バージョン : 1.3
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-05 1.0  二瓶大輔     新規作成
* 2008-06-09 1.1  二瓶大輔     変更要求#42対応
* 2009-02-16 1.2  二瓶大輔     本番障害#469対応
* 2009-03-13 1.3  飯田  甫     本番障害#1300対応
* 2009-11-26 1.4  吉元強樹     本稼動障害#59対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo440001j.server;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

import java.util.ArrayList;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Date;
import oracle.jbo.domain.Number;
/***************************************************************************
 * 支給指示要約結果ビューオブジェクトクラスです。
 * @author  ORACLE 二瓶 大輔
 * @version 1.3
 ***************************************************************************
 */
public class XxpoProvReqtResultVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoProvReqtResultVOImpl()
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
// 2009-11-26 v1.4 T.Yoshimoto Mod Start 本稼動障害#59対応
    //int bindCount = 0;                                  // バインド変数カウント
    int bindCount = 2;                                  // バインド変数カウント
// 2009-11-26 v1.4 T.Yoshimoto Mod End 本稼動障害#59対応

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
    String exeType      = (String)shParams.get("exeType");      // 起動タイプ  
    String baseReqNo    = (String)shParams.get("baseReqNo");    // 元依頼No
// 2009-03-13 H.Iida ADD START 本番障害#1300
    String fixClass    = (String)shParams.get("fixClass");      // 金額確定
// 2009-03-13 H.Iida ADD END
    
    // 起動タイプ(必須)
// 2009-11-26 v1.4 T.Yoshimoto Add Start 本稼動障害#59対応
    parameters.add(exeType);  // VO内の起動タイプへのバインド
    parameters.add(exeType);  // VO内の起動タイプへのバインド

    // 起動タイプが「12：パッカー･外注工場用」の場合
    if (XxpoConstants.EXE_TYPE_12.equals(exeType)) 
    {
      // セキュリティ情報VIEWを適用
      whereClause.append(" EXISTS (");
      whereClause.append("          SELECT 1 ");
      whereClause.append("          FROM   xxpo_security_supply_v         xssv "  );
      whereClause.append("                ,xxcmn_lookup_values_v          xlvvs " );
      whereClause.append("          WHERE  xlvvs.attribute3                         = xssv.security_class " );
      whereClause.append("          AND    xssv.vendor_code                         = vendor_code "         );
      whereClause.append("          AND    NVL(xssv.vendor_site_code, ship_to_code) = ship_to_code "        );
      whereClause.append("          AND    xssv.user_id                             = FND_GLOBAL.USER_ID "  );
      whereClause.append("          AND    xlvvs.lookup_type                        = 'XXPO_START_UP_TYPE'" );
      whereClause.append("          AND    xlvvs.lookup_code                        = :" + bindCount++ );
      whereClause.append("         ) ");
      //起動タイプ
      parameters.add(exeType);      
    }
    
    // 起動タイプが「13：東洋埠頭用」「15：資材メーカー用」の場合
    if (XxpoConstants.EXE_TYPE_13.equals(exeType)
      || XxpoConstants.EXE_TYPE_15.equals(exeType))
    {
      // セキュリティ情報VIEWを適用
      whereClause.append(" EXISTS (");
      whereClause.append("          SELECT 1 ");
      whereClause.append("          FROM   xxpo_security_supply_v         xssv "  );
      whereClause.append("                ,xxcmn_lookup_values_v          xlvvs " );
      whereClause.append("          WHERE  xlvvs.attribute3   = xssv.security_class "  );
      whereClause.append("          AND    xssv.segment1      = ship_whse_code "       );
      whereClause.append("          AND    xssv.user_id       = FND_GLOBAL.USER_ID "   );
      whereClause.append("          AND    xlvvs.lookup_type  = 'XXPO_START_UP_TYPE' " );
      whereClause.append("          AND    xlvvs.lookup_code  = :" + bindCount++ );
      whereClause.append("         ) ");
      //起動タイプ
      parameters.add(exeType);      
    }

// 2009-11-26 v1.4 T.Yoshimoto Add End 本稼動障害#59対応

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
    // 元依頼Noが入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(baseReqNo))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where句生成
      whereClause.append(" (request_no = :" + bindCount++);
      //検索値をセット
      parameters.add(baseReqNo);      
      // Where句生成
      whereClause.append(" OR base_request_no = :" + bindCount++ + ") ");
      //検索値をセット
      parameters.add(baseReqNo);      
    }
// 2009-03-13 H.Iida ADD START 本番障害#1300
    // 金額指定が入力されていた場合
    if (!XxcmnUtility.isBlankOrNull(fixClass))
    {
      XxcmnUtility.andAppend(whereClause);
      // Where句生成
      whereClause.append("fix_class = :" + bindCount++);
      //検索値をセット
      parameters.add(fixClass);      
    }
// 2009-03-13 H.Iida ADD END

    // 検索条件をVOにセット
    setWhereClause(whereClause.toString());

// 2009-02-16 v1.2 D.Nihei Add Start 本番障害#469対応
    // ヒント句を以下の条件の場合使用する。
    if (!XxcmnUtility.isBlankOrNull(transStatus)
      && XxcmnUtility.isBlankOrNull(vendorCode)
      && XxcmnUtility.isBlankOrNull(shipToCode)
      && XxcmnUtility.isBlankOrNull(shipWhseCode)
      && XxcmnUtility.isBlankOrNull(reqNo)
      && XxcmnUtility.isBlankOrNull(shipToNo)) 
    {
        setQueryOptimizerHint(" index(QRSLT.xoha xxwsh_oh_n29) ");
    } else
    {
        setQueryOptimizerHint(null);
    }
// 2009-02-16 v1.2 D.Nihei Add End

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