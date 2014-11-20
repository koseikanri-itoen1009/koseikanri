/*============================================================================
* ファイル名 : XxpoVendorSupplyVOImpl
* 概要説明   : 外注出来高報告:検索ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-10 1.0  伊藤ひとみ   新規作成
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo340001j.server;
import com.sun.java.util.collections.HashMap;

import itoen.oracle.apps.xxcmn.util.XxcmnUtility;

import java.util.ArrayList;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;
/***************************************************************************
 * 外注出来高報告:検索ビューオブジェクトクラスです。
 * @author  ORACLE 伊藤 ひとみ
 * @version 1.0
 ***************************************************************************
 */
public class XxpoVendorSupplyVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoVendorSupplyVOImpl()
  {
  }
  /*****************************************************************************
   * VOの初期化を行います。
   * @param searchParams         - 検索キーパラメータ
   * @param manufacturedDateFrom - 生産日FROM
   * @param manufacturedDateTo   - 生産日TO
   * @param productedDateFrom    - 製造日FROM
   * @param productedDateTo      - 製造日TO
   ****************************************************************************/
  public void initQuery(
    HashMap        searchParams,         // 検索キーパラメータ
    java.sql.Date  manufacturedDateFrom, // 生産日FROM
    java.sql.Date  manufacturedDateTo,   // 生産日TO
    java.sql.Date  productedDateFrom,    // 製造日FROM
    java.sql.Date  productedDateTo       // 製造日TO
   )
  {
    StringBuffer whereClause = new StringBuffer(1000);  // WHERE句作成用オブジェクト
    ArrayList parameters = new ArrayList();             // バインド変数設定値
    int bindCount = 0;                                  // バインド変数カウント

    // 初期化
    setWhereClauseParams(null);

    // *************************** //
    // *        条件作成         * //
    // *************************** //
    // 検索キー取得
    String lotNumber   = (String)searchParams.get("lotNumber");
    String vendorCode  = (String)searchParams.get("vendorCode");
    String factoryCode = (String)searchParams.get("factoryCode");
    String itemCode    = (String)searchParams.get("itemCode");
    String koyuCode    = (String)searchParams.get("koyuCode");
    String corrected   = (String)searchParams.get("corrected");

    // ロット番号に入力がある場合、条件に追加
    if (XxcmnUtility.isBlankOrNull(lotNumber) == false)
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND lot_number = :" + bindCount);
      
      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" lot_number = :" + bindCount);
      }
      //バインド変数をカウント
      bindCount = bindCount + 1;     
      //検索値をセット
      parameters.add(lotNumber);
    }

    // 生産日FROMに入力がある場合、条件に追加
    if (XxcmnUtility.isBlankOrNull(manufacturedDateFrom) == false)
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND manufactured_date >= :" + bindCount);
      
      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" manufactured_date >= :" + bindCount);
      }
      //バインド変数をカウント
      bindCount = bindCount + 1;
      //検索値をセット
      parameters.add(manufacturedDateFrom);
    }

    // 生産日TOに入力がある場合、条件に追加
    if (XxcmnUtility.isBlankOrNull(manufacturedDateTo) == false)
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND manufactured_date <= :" + bindCount);
      
      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" manufactured_date <= :" + bindCount);
      }
      //バインド変数をカウント
      bindCount = bindCount + 1;   
      //検索値をセット
      parameters.add(manufacturedDateTo);
    }

    // 取引先に入力がある場合、条件に追加
    if (XxcmnUtility.isBlankOrNull(vendorCode) == false)
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND vendor_code = :" + bindCount);
      
      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" vendor_code = :" + bindCount);
      }
      //バインド変数をカウント
      bindCount = bindCount + 1;
      //検索値をセット
      parameters.add(vendorCode);
    }

    // 工場に入力がある場合、条件に追加
    if (XxcmnUtility.isBlankOrNull(factoryCode) == false)
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND factory_code = :" + bindCount);
      
      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" factory_code = :" + bindCount);
      }
      //バインド変数をカウント
      bindCount = bindCount + 1;   
      //検索値をセット
      parameters.add(factoryCode);
    }

    // 品目に入力がある場合、条件に追加
    if (XxcmnUtility.isBlankOrNull(itemCode) == false)
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND item_code = :" + bindCount);
      
      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" item_code = :" + bindCount);
      }
      //バインド変数をカウント
      bindCount = bindCount + 1;
      //検索値をセット
      parameters.add(itemCode);
    }

    // 固有記号に入力がある場合、条件に追加
    if (XxcmnUtility.isBlankOrNull(koyuCode) == false)
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND koyu_code = :" + bindCount);
      
      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" koyu_code = :" + bindCount);
      }
      //バインド変数をカウント
      bindCount = bindCount + 1;
      //検索値をセット
      parameters.add(koyuCode);
    }

    // 製造日FROMに入力がある場合、条件に追加
    if (XxcmnUtility.isBlankOrNull(productedDateFrom) == false)
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND producted_date >= :" + bindCount);
      
      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" producted_date >= :" + bindCount);
      }
      //バインド変数をカウント
      bindCount = bindCount + 1;
      //検索値をセット
      parameters.add(productedDateFrom);
    }

    // 製造日TOに入力がある場合、条件に追加
    if (XxcmnUtility.isBlankOrNull(productedDateTo) == false)
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND producted_date <= :" + bindCount);
      
      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" producted_date <= :" + bindCount);
      }
      //バインド変数をカウント
      bindCount = bindCount + 1;
      //検索値をセット
      parameters.add(productedDateTo);
    }

    // 訂正有に入力がある場合、「訂正数量に入力のあるもの」
    if (XxcmnUtility.isBlankOrNull(corrected) == false)
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND corrected_quantity IS NOT NULL ");
      
      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" corrected_quantity IS NOT NULL ");
      }
    
    // 訂正有に入力がない場合、「訂正数量に入力のないもの」
    } else
    {
      // 条件追加1件目以降の場合
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND corrected_quantity IS NULL ");
      
      // 条件追加1件目の場合
      } else
      {
        whereClause.append(" corrected_quantity IS NULL ");
      }
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

    // *************************** //
    // *        検索実行         * //
    // *************************** //  
    executeQuery();
  }
}