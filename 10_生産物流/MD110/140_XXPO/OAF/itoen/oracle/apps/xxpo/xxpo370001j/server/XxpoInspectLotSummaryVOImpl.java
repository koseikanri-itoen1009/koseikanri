/*============================================================================
* ファイル名 : XxpoInspectLotSummaryVOImpl
* 概要説明   : 検査ロット検索結果ビューオブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者         修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-01-29 1.0  戸谷田大輔     新規作成
* 2008-05-09 1.1  熊本 和郎      内部変更要求#28,41,43対応
*============================================================================
*/
package itoen.oracle.apps.xxpo.xxpo370001j.server;

import com.sun.java.util.collections.ArrayList;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.List;

import itoen.oracle.apps.xxcmn.util.XxcmnUtility;

import oracle.apps.fnd.framework.server.OAViewObjectImpl;

import oracle.jbo.domain.Number;
// 20080509 add start kumamoto
import oracle.jbo.domain.Date;
// 20080509 add end kumamoto
/***************************************************************************
 * 検査ロット検索結果ビューオブジェクトクラスです。
 * @author  ORACLE 戸谷田 大輔
 * @version 1.0
 ***************************************************************************
 */
public class XxpoInspectLotSummaryVOImpl extends OAViewObjectImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxpoInspectLotSummaryVOImpl()
  {
  }

  /***************************************************************************
   * VOの初期化を行います。
	 * @param HashMap    - 検索条件
   ***************************************************************************
   */
  public void initQuery(HashMap searchParams)
  {
    // WHERE句の初期化
    setWhereClauseParams(null);

    // 変数定義
    int bindCount = 0;                                  // バインド変数
    List list = new ArrayList();                        // 検索条件値を格納
    StringBuffer whereClause = new StringBuffer(1000);  // WHERE句を格納

    // 検索キーの取得
    String vendorCode = (String)searchParams.get("vendorCode");
    String itemCode = (String)searchParams.get("itemCode");
    String lotNo = (String)searchParams.get("lotNo");
    String productFactory = (String)searchParams.get("productFactory");
    String productLotNo = (String)searchParams.get("productLotNo");
// 20080509 mod start kumamoto
//    oracle.jbo.domain.Date attribute1From 
//      = (oracle.jbo.domain.Date)searchParams.get("productDateFrom");
//    oracle.jbo.domain.Date attribute1To
//      = (oracle.jbo.domain.Date)searchParams.get("productDateTo");
//    oracle.jbo.domain.Date creationDateFrom
//      = (oracle.jbo.domain.Date)searchParams.get("creationDateFrom");
//    oracle.jbo.domain.Date creationDateTo
//      = (oracle.jbo.domain.Date)searchParams.get("creationDateTo");

    Date attribute1From = (Date)searchParams.get("productDateFrom");
    Date attribute1To = (Date)searchParams.get("productDateTo");
    Date creationDateFrom = (Date)searchParams.get("creationDateFrom");
    Date creationDateTo = (Date)searchParams.get("creationDateTo");
// 20080509 mod end kumamoto
    Number itemId = (Number)searchParams.get("itemId");
    Number qtInspectReqNo = (Number)searchParams.get("qtInspectReqNo");

    // *************************** //
    // *         条件作成         * //
    // *************************** //
    // 取引先
    if (!XxcmnUtility.isBlankOrNull(vendorCode))
    {
      // 追加条件1件目以降
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND attribute8 LIKE :" + bindCount);
      // 追加条件1件目
      } else
      {
        whereClause.append(" attribute8 LIKE :" + bindCount);
      }
      // バインド変数のカウント
      bindCount ++;
      // 検索キーをセット
      list.add(vendorCode);
    }

    // 品目に値が入力されていた場合、品目IDを検索条件に追加
    if (!XxcmnUtility.isBlankOrNull(itemId))
    {
      // 追加条件1件目以降
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND item_id LIKE :" + bindCount);
      // 追加条件1件目
      } else
      {
        whereClause.append(" item_id LIKE :" + bindCount);
      }
      // バインド変数のカウント
      bindCount ++;
      // 検索キーをセット
      list.add(itemId);
    }

    // ロット番号
    if (!XxcmnUtility.isBlankOrNull(lotNo))
    {
      // 追加条件1件目以降
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND lot_no LIKE :" + bindCount);
      // 追加条件1件目
      } else
      {
        whereClause.append(" lot_no LIKE :" + bindCount);
      }
      // バインド変数をカウント
      bindCount ++;
      // 検索キーをセット
      list.add(lotNo);
    }

    // 製造工場
    if (!XxcmnUtility.isBlankOrNull(productFactory))
    {
      // 追加条件1件目以降
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND attribute20 LIKE :" + bindCount);
      // 検索条件1件目
      } else
      {
        whereClause.append(" attribute20 LIKE :" + bindCount);
      }
      // バインド変数をカウント
      bindCount ++;
      // 検索キーをセット
      list.add(productFactory);
    }

    // 製造ロット番号
    if (!XxcmnUtility.isBlankOrNull(productLotNo))
    {
      // 追加条件1件目以降
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND attribute21 LIKE :" + bindCount);
      // 追加条件1件目
      } else
      {
        whereClause.append(" attribute21 LIKE :" + bindCount);
      }
      // バインド変数をカウント
      bindCount ++;
      // 検索キーをセット
      list.add(productLotNo);
    }

    // 製造日/仕入日(自)
    if (!XxcmnUtility.isBlankOrNull(attribute1From))
    {
      // 追加条件1件目以降
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND attribute1 >= :" + bindCount);
      // 追加条件1件目
      } else
      {
        whereClause.append(" attribute1 >= :" + bindCount);
      }
      // バインド変数をカウント
      bindCount ++;
      // 検索キーをセット
      list.add(attribute1From);
    }
    
    // 製造日/仕入日(至)
    if (!XxcmnUtility.isBlankOrNull(attribute1To))
    {
      // 追加条件1件目以降
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND attribute1 <= :" + bindCount);
      // 追加条件1件目
      } else
      {
        whereClause.append(" attribute1 <= :" + bindCount);
      }
      // バインド変数をカウント
      bindCount ++;
      // 検索キーをセット
      list.add(attribute1To);
    }

    // 入力日(自)
    if (!XxcmnUtility.isBlankOrNull(creationDateFrom))
    {
      // 検索条件1件目以降
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND trunc(creation_date) >= :" + bindCount);
      // 検索条件1件目
      } else
      {
        whereClause.append(" trunc(creation_date) >= :" + bindCount);
      }
      // バインド変数をカウント
      bindCount ++;
      // 検索キーをセット
      list.add(creationDateFrom);
    }

    // 入力日(至)
    if (!XxcmnUtility.isBlankOrNull(creationDateTo))
    {
      // 検索条件1件目以降
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND trunc(creation_date) <= :" + bindCount);
      // 検索条件1件目
      } else
      {
        whereClause.append(" trunc(creation_date) <= :" + bindCount);
      }
      // バインド変数をカウント
      bindCount ++;
      // 検索キーをセット
      list.add(creationDateTo);
    }

    // 検査依頼No
    if (!XxcmnUtility.isBlankOrNull(qtInspectReqNo))
    {
      // 追加条件1件目以降
      if (whereClause.length() != 0)
      {
        whereClause.append(" AND qt_inspect_req_no LIKE :" + bindCount);
      // 追加条件1件目
      } else
      {
        whereClause.append(" qt_inspect_req_no LIKE :" + bindCount);
      }
      // バインド変数のカウント
      bindCount ++;
      // 検索キーをセット
      list.add(qtInspectReqNo);
    }
    // 検索条件をVOにセット
    setWhereClause(whereClause.toString());

    // バインド変数に値が設定された場合
    if (bindCount > 0)
    {
      // 検索値配列を取得
      Object[] params = new Object[bindCount];
      params = list.toArray();
      
      // SELECT文実行
      setWhereClauseParams(params);
      executeQuery();

    // 設定されなかった場合
    } else
    {
      return;
    }
  }
}