/*============================================================================
* ファイル名 : XxpoOrderHeaderVOImpl
* 概要説明   : 発注受入詳細:発注ヘッダビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-04-03 1.0  吉元強樹     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo310001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import com.sun.java.util.collections.HashMap;
import java.util.ArrayList;
import itoen.oracle.apps.xxcmn.util.XxcmnUtility;

/***************************************************************************
 * 発注ヘッダビューオブジェクトです。
 * @author  SCS 吉元 強樹
 * @version 1.0
 ***************************************************************************
 */
public class XxpoOrderHeaderVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoOrderHeaderVOImpl()
  {
  }

  /*****************************************************************************
   * VOの初期化を行います。
   * @param searchParams 検索パラメータ用HashMap
   ****************************************************************************/
  public void initQuery(
    HashMap searchParams         // 検索キーパラメータ
   )
  {

    StringBuffer whereClause = new StringBuffer(1000);  // WHERE句作成用オブジェクト
    ArrayList parameters = new ArrayList();             // バインド変数設定値
    int bindCount = 0;                                  // バインド変数カウント

    // 初期化
    setWhereClauseParams(null);

    // 検索条件取得
    String headerNumber        = (String)searchParams.get("HeaderNumber");        // 発注No.
    String requestNumber       = (String)searchParams.get("RequestNumber");       // 支給No.

    // *************************** //
    // *        条件作成         * //
    // *************************** //
    // 発注No.が入力されていた場合
    if (XxcmnUtility.isBlankOrNull(headerNumber) == false)
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND header_number = :" + bindCount);
      
      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" header_number = :" + bindCount);
      }
      //バインド変数をカウント
      bindCount = bindCount + 1;
      //検索値をセット
      parameters.add(headerNumber);
    }
        
    // 支給No.が入力されていた場合
    if (XxcmnUtility.isBlankOrNull(requestNumber) == false)
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND request_number = :" + bindCount);
      
      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" request_number = :" + bindCount);
      }
      //バインド変数をカウント
      bindCount = bindCount + 1;
      //検索値をセット
      parameters.add(requestNumber);
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
    
    executeQuery();
  }
}