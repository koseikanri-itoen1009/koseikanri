/*============================================================================
* ファイル名 : XxpoOrderReceiptVOImpl
* 概要説明   : 発注受入:検索ビューオブジェクト
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-03-31 1.0  吉元強樹     新規作成
* 2008-11-05 1.1  伊藤ひとみ   統合テスト指摘103対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo310001j.server;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import com.sun.java.util.collections.HashMap;
import java.util.ArrayList;

import itoen.oracle.apps.xxcmn.util.XxcmnUtility;

/***************************************************************************
 * 検索ビューオブジェクトです。
 * @author  SCS 吉元 強樹
 * @version 1.1
 ***************************************************************************
 */
public class XxpoOrderReceiptVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoOrderReceiptVOImpl()
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
    String headerNumber        = (String)searchParams.get("headerNumber");        // 発注No.
    String requestNumber       = (String)searchParams.get("requestNumber");       // 支給No.
    String vendorCode          = (String)searchParams.get("vendorCode");          // 取引先コード
    String vendorId            = (String)searchParams.get("vendorId");            // 取引先ID     
    String mediationCode       = (String)searchParams.get("mediationCode");       // 斡旋者コード
    String mediationId         = (String)searchParams.get("mediationId");         // 斡旋者ID
    String deliveryDateFrom    = (String)searchParams.get("deliveryDateFrom");    // 納品日(開始)
    String deliveryDateTo      = (String)searchParams.get("deliveryDateTo");      // 納品日(終了) 
    String status              = (String)searchParams.get("status");              // ステータス
    String location            = (String)searchParams.get("location");            // 納品先コード
    String department          = (String)searchParams.get("department");          // 発注部署コード
    String approved            = (String)searchParams.get("approved");            // 承諾要
    String purchase            = (String)searchParams.get("purchase");            // 直送区分
    String orderApproved       = (String)searchParams.get("orderApproved");       // 発注承諾
    String purchaseApproved    = (String)searchParams.get("purchaseApproved");    // 仕入承諾
    String peopleCode          = (String)searchParams.get("PeopleCode");          // 従業員区分                                            // 自取引先ID
  


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
// 2008-11-05 H.Itou Add Start 統合テスト指摘103
    // 発注Noが入力されていない場合、その他の検索条件を追加
    } else
    {
// 2008-11-05 H.Itou Add End 統合テスト指摘103
        
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
        
      // 取引先が入力されていた場合
      if (XxcmnUtility.isBlankOrNull(vendorId) == false)
      {
        // 条件追加1件目以降の場合
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND vendor_id = :" + bindCount);
      
        // 条件追加1件目の場合
        } else
        {
          whereClause.append(" vendor_id = :" + bindCount);
        }
        //バインド変数をカウント
        bindCount = bindCount + 1;     
        //検索値をセット
        parameters.add(vendorId);      
      }

      // 斡旋者が入力されていた場合
      if (XxcmnUtility.isBlankOrNull(mediationId) == false)
      {
        // 条件追加1件目以降の場合
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND mediation_id = :" + bindCount);
      
        // 条件追加1件目の場合
        } else
        {
          whereClause.append(" mediation_id = :" + bindCount);
        }
        //バインド変数をカウント
        bindCount = bindCount + 1;     
        //検索値をセット
        parameters.add(mediationId);      
      }

      // 納入日Fromが入力されていた場合
      if (XxcmnUtility.isBlankOrNull(deliveryDateFrom) == false)
      {
        // 条件追加1件目以降の場合
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND delivery_date >= :" + bindCount);
      
        // 条件追加1件目の場合
        } else
        {
          whereClause.append(" delivery_date >= :" + bindCount);
        }
        //バインド変数をカウント
        bindCount = bindCount + 1;     
        //検索値をセット
        parameters.add(deliveryDateFrom);
      }

      // 納入日Toが入力されていた場合
      if (XxcmnUtility.isBlankOrNull(deliveryDateTo) == false)
      {
        // 条件追加1件目以降の場合
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND delivery_date <= :" + bindCount);
      
        // 条件追加1件目の場合
        } else
        {
          whereClause.append(" delivery_date <= :" + bindCount);
        }
        //バインド変数をカウント
        bindCount = bindCount + 1;     
        //検索値をセット
        parameters.add(deliveryDateTo);      
      }

      // ステータスが入力されていた場合
      if (XxcmnUtility.isBlankOrNull(status) == false)
      {
        // 条件追加1件目以降の場合
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND status_code = :" + bindCount);
        // 条件追加1件目の場合
        }else
        {
          whereClause.append(" status_code = :" + bindCount); 
        }
      
        //バインド変数をカウント
        bindCount = bindCount + 1;     
        //検索値をセット
        parameters.add(status);  
      }

      // 納入先が入力されていた場合
      if (XxcmnUtility.isBlankOrNull(location) == false)
      {
        // 条件追加1件目以降の場合
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND location_code = :" + bindCount);
      
        // 条件追加1件目の場合
        } else
        {
          whereClause.append(" location_code = :" + bindCount);
        }
        //バインド変数をカウント
        bindCount = bindCount + 1;     
        //検索値をセット
        parameters.add(location);      
      }

      // 発注部署が入力されていた場合
      if (XxcmnUtility.isBlankOrNull(department) == false)
      {
        // 条件追加1件目以降の場合
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND department_code = :" + bindCount);
      
        // 条件追加1件目の場合
        } else
        {
          whereClause.append(" department_code = :" + bindCount);
        }
        //バインド変数をカウント
        bindCount = bindCount + 1;     
        //検索値をセット
        parameters.add(department);      
      }

      // 承諾要が入力されていた場合
      if (XxcmnUtility.isBlankOrNull(approved) == false)
      {
        // 条件追加1件目以降の場合
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND approved_flag = :" + bindCount);
      
        // 条件追加1件目の場合
        } else
        {
          whereClause.append(" approved_flag = :" + bindCount);
        }
        //バインド変数をカウント
        bindCount = bindCount + 1;
      
        //検索値をセット
        parameters.add(approved);      
      }

      // 直送区分が入力されていた場合
      if (XxcmnUtility.isBlankOrNull(purchase) == false)
      {
        // 条件追加1件目以降の場合
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND dropship_code = :" + bindCount);
      
        // 条件追加1件目の場合
        } else
        {
          whereClause.append(" dropship_code = :" + bindCount);
        }
        //バインド変数をカウント
        bindCount = bindCount + 1;

        //検索値をセット
        parameters.add(purchase);      
      }

      // 発注承諾が入力されていた場合
      if (XxcmnUtility.isBlankOrNull(orderApproved) == false)
      {
        // 条件追加1件目以降の場合
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND orderapproved_flag = :" + bindCount);
      
        // 条件追加1件目の場合
        } else
        {
          whereClause.append(" orderapproved_flag = :" + bindCount);
        }
        //バインド変数をカウント
        bindCount = bindCount + 1;
      
        //検索値をセット
        parameters.add(orderApproved);      
      }

      // 仕入承諾が入力されていた場合
      if (XxcmnUtility.isBlankOrNull(purchaseApproved) == false)
      {
        // 条件追加1件目以降の場合
        if (whereClause.length() != 0)
        {
          whereClause.append(" AND purchaseapproved_flag = :" + bindCount);
      
        // 条件追加1件目の場合
        } else
        {
          whereClause.append(" purchaseapproved_flag = :" + bindCount);
        }
        //バインド変数をカウント
        bindCount = bindCount + 1;
      
        //検索値をセット
        parameters.add(purchaseApproved);      
      }
// 2008-11-05 H.Itou Add Start 統合テスト指摘103
    }
// 2008-11-05 H.Itou Add End 統合テスト指摘103
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