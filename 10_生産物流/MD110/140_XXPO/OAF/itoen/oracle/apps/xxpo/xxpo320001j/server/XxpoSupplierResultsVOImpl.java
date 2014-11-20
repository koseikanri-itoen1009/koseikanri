/*============================================================================
* ファイル名 : XxpoSupplierResultsVOImpl
* 概要説明   : 仕入出荷実績:検索ビューオブジェクト
* バージョン : 1.1
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-02-18 1.0  吉元強樹     新規作成
* 2008-11-04 1.1  二瓶大輔     統合障害#103対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo320001j.server;

import com.sun.java.util.collections.HashMap;
import java.util.ArrayList;

import oracle.jbo.domain.Number;
import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import itoen.oracle.apps.xxcmn.util.XxcmnUtility;
import itoen.oracle.apps.xxpo.util.XxpoConstants;

/***************************************************************************
 * 検索ビューオブジェクトです。
 * @author  SCS 吉元 強樹
 * @version 1.1
 ***************************************************************************
 */
public class XxpoSupplierResultsVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoSupplierResultsVOImpl()
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
    String cancelSearch        = (String)searchParams.get("cancelSearch");        // 取消検索
    String purchaseApproved    = (String)searchParams.get("purchaseApproved");    // 仕入承諾
    String peopleCode          = (String)searchParams.get("PeopleCode");          // 従業員区分
    Number outSideUsrVendorId  = null;                                            // 自取引先ID
    Object outSideUsrFactoryCode = null;                                          // 自工場コード

    // *************************** //
    // *        条件作成         * //
    // *************************** //
    
    // 従業員区分が2:外部ユーザの場合
    if (XxpoConstants.PEOPLE_CODE_O.equals(peopleCode))
    {
      // 自取引先ID・自工場コードを取得
      outSideUsrVendorId = (Number)searchParams.get("OutSideUsrVendorId");
      outSideUsrFactoryCode = searchParams.get("OutSideUsrFactoryCode");

      // 自工場IDに設定がない場合、自工場コードを設定しない
      if (XxcmnUtility.isBlankOrNull(outSideUsrFactoryCode))
      {
        whereClause.append(" ((mediation_id = :" + bindCount + ")");
        whereClause.append(" OR (vendor_id = :" + (++bindCount) +"))");

        //バインド変数をカウント
        bindCount = bindCount + 1;
      
        parameters.add(outSideUsrVendorId); 
        parameters.add(outSideUsrVendorId); 

      // 自工場IDに設定がある場合、自工場コードを設定
      } else
      {
        
        // 紐付く発注明細に、自工場コードでない発注明細が存在しないもの。
        whereClause.append(" ((mediation_id = :" + bindCount + ")");
        whereClause.append(" OR ((vendor_id = :" + (++bindCount) +")");
        whereClause.append("     AND (NOT EXISTS ( " );
        whereClause.append("           SELECT 1 " );
        whereClause.append("           FROM   po_lines_all pla " );
        whereClause.append("           WHERE  pla.po_header_id = header_id " );
        whereClause.append("           AND    pla.attribute2  <> :" + (++bindCount) + ")))) " );

        //バインド変数をカウント
        bindCount = bindCount + 1;
      
        parameters.add(outSideUsrVendorId); 
        parameters.add(outSideUsrVendorId);
        parameters.add(outSideUsrFactoryCode); 

      }

    }
    
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
// 2008-11-04 v1.1 D.Nihei Add Start 統合障害#103対応 
    } else
    {
// 2008-11-04 v1.1 D.Nihei Add End
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

      // 取消検索がONになっていない場合(取消は検索不可)
      if (XxcmnUtility.isBlankOrNull(cancelSearch) == true)
      {
  // 20080225 add Start
        // ステータスが入力されていない、又は、取消(99)で無い場合
        if ((XxcmnUtility.isBlankOrNull(status) == true) 
          || !(XxpoConstants.STATUS_CANCEL.equals(status)))
        {
  // 20080225 add End
          // 条件追加1件目以降の場合
          if (whereClause.length() != 0)
          {
            whereClause.append(" AND status_code != 99");
          // 条件追加1件目の場合
          }else
          {
          whereClause.append(" status_code != 99"); 
          }
        }
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
// 2008-11-04 v1.1 D.Nihei Add Start 統合障害#103対応 
      }
// 2008-11-04 v1.1 D.Nihei Add End
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